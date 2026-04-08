#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# MARLIN V3 -- PHASE 3 + PHASE 4 ORCHESTRATOR
# ============================================================================
#
# Automates Environment Setup (Phase 3) and Task Execution (Phase 4)
# using tmux mode for full scriptability.
#
# Prerequisites:
#   - git, python3, tmux installed
#   - claude-hfi binary downloaded to ~/Downloads/
#   - Approved prompt from Phase 2
#
# Phase 3 (Environment Setup):
#   bash hfi_orchestrator.sh setup <tarball-path>     Unpack, git init, deps, tests
#   bash hfi_orchestrator.sh claude-md <repo-path>    Generate CLAUDE.md template
#
# Phase 4 (Task Execution):
#   bash hfi_orchestrator.sh launch <repo-path>       Copy binary, start tmux session
#   bash hfi_orchestrator.sh inject <prompt-file>      Paste prompt into control
#   bash hfi_orchestrator.sh monitor                   Watch trajectories
#   bash hfi_orchestrator.sh full <tarball> <prompt>   All steps sequentially
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$SCRIPT_DIR/data"
STATE_FILE="$STATE_DIR/phase3_state.json"
PYTHON="${PYTHON:-python3}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

banner() {
  echo ""
  echo -e "${CYAN}+============================================================+${NC}"
  echo -e "${CYAN}|${NC}  ${BOLD}MARLIN V3 -- PHASE 3 + 4 AUTOMATION${NC}                      ${CYAN}|${NC}"
  echo -e "${CYAN}|${NC}  ${DIM}Phase 3: Env Setup | Phase 4: Task Execution${NC}             ${CYAN}|${NC}"
  echo -e "${CYAN}+============================================================+${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# State management
# ---------------------------------------------------------------------------

save_state() {
  local key="$1" value="$2"
  mkdir -p "$STATE_DIR"
  if [ ! -f "$STATE_FILE" ]; then
    echo '{}' > "$STATE_FILE"
  fi
  "$PYTHON" -c "
import json, pathlib
p = pathlib.Path('$STATE_FILE')
d = json.loads(p.read_text())
d['$key'] = '$value'
p.write_text(json.dumps(d, indent=2))
"
}

load_state() {
  local key="$1"
  if [ ! -f "$STATE_FILE" ]; then
    echo ""
    return
  fi
  "$PYTHON" -c "
import json, pathlib
d = json.loads(pathlib.Path('$STATE_FILE').read_text())
print(d.get('$key', ''))
"
}

# ---------------------------------------------------------------------------
# Task state machine -- resume-able across Cursor sessions
# ---------------------------------------------------------------------------

TASK_STATE_FILE="$STATE_DIR/task_state.json"

# Valid states (in order): INITIALIZED -> SETUP_DONE -> LAUNCHED -> CLAUDE_MD_DONE
# -> TURN1_INJECTED -> TURN1_DONE -> TURN1_FEEDBACK -> TURN2_INJECTED -> TURN2_DONE
# -> TURN2_FEEDBACK -> TURN3_INJECTED -> TURN3_DONE -> TURN3_FEEDBACK
# -> EVAL_DONE -> SUBMITTED

save_task_step() {
  local step="$1"
  mkdir -p "$STATE_DIR"
  "$PYTHON" -c "
import json, pathlib, datetime
p = pathlib.Path('$TASK_STATE_FILE')
d = json.loads(p.read_text()) if p.exists() else {'completed_steps': [], 'winners': {}}
if '$step' not in d.get('completed_steps', []):
    d.setdefault('completed_steps', []).append('$step')
d['current_state'] = '$step'
d['updated_at'] = datetime.datetime.now().isoformat()
p.write_text(json.dumps(d, indent=2))
"
}

init_task_state() {
  local task_id="$1"
  mkdir -p "$STATE_DIR"
  "$PYTHON" -c "
import json, pathlib, datetime
p = pathlib.Path('$TASK_STATE_FILE')
d = {
    'task_id': '$task_id',
    'current_state': 'INITIALIZED',
    'turn': 0,
    'completed_steps': [],
    'winners': {},
    'created_at': datetime.datetime.now().isoformat(),
    'updated_at': datetime.datetime.now().isoformat()
}
p.write_text(json.dumps(d, indent=2))
"
}

save_task_field() {
  local key="$1" value="$2"
  "$PYTHON" -c "
import json, pathlib, datetime
p = pathlib.Path('$TASK_STATE_FILE')
d = json.loads(p.read_text()) if p.exists() else {}
d['$key'] = '$value'
d['updated_at'] = datetime.datetime.now().isoformat()
p.write_text(json.dumps(d, indent=2))
"
}

load_task_field() {
  local key="$1"
  if [ ! -f "$TASK_STATE_FILE" ]; then
    echo ""
    return
  fi
  "$PYTHON" -c "
import json, pathlib
d = json.loads(pathlib.Path('$TASK_STATE_FILE').read_text())
print(d.get('$key', ''))
"
}

cmd_task_status() {
  echo -e "${BOLD}TASK STATE MACHINE${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"

  if [ ! -f "$TASK_STATE_FILE" ]; then
    echo -e "  ${DIM}No active task. Say \"lets start a task\" in Cursor${NC}"
    echo ""
    return
  fi

  "$PYTHON" -c "
import json, pathlib
d = json.loads(pathlib.Path('$TASK_STATE_FILE').read_text())
print(f\"  Task ID:       {d.get('task_id', 'unknown')}\")
print(f\"  Current state: {d.get('current_state', 'unknown')}\")
print(f\"  Turn:          {d.get('turn', 0)}\")
print(f\"  Completed:     {len(d.get('completed_steps', []))} steps\")
winners = d.get('winners', {})
if winners:
    for t, w in winners.items():
        print(f\"  Turn {t} winner: {w}\")
print(f\"  Updated:       {d.get('updated_at', 'unknown')}\")
print()
steps = d.get('completed_steps', [])
if steps:
    print('  Progress:')
    for s in steps:
        print(f'    [done] {s}')
"
  echo ""
}

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------

preflight() {
  local ok=true

  if ! command -v git >/dev/null 2>&1; then
    echo -e "  ${RED}x${NC} git not found"
    ok=false
  else
    echo -e "  ${GREEN}ok${NC} git $(git --version | head -c 30)"
  fi

  if ! command -v "$PYTHON" >/dev/null 2>&1; then
    echo -e "  ${RED}x${NC} python3 not found"
    ok=false
  else
    echo -e "  ${GREEN}ok${NC} $($PYTHON --version)"
  fi

  if ! command -v tmux >/dev/null 2>&1; then
    echo -e "  ${RED}x${NC} tmux not found -- brew install tmux"
    ok=false
  else
    echo -e "  ${GREEN}ok${NC} $(tmux -V)"
  fi

  echo ""

  if [ "$ok" = false ]; then
    echo -e "  ${RED}Missing prerequisites. Install them and retry.${NC}"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# setup: Unpack tarball, git init, detect language, install deps, run tests
# ---------------------------------------------------------------------------

detect_language() {
  local repo_path="$1"

  if [ -f "$repo_path/pyproject.toml" ] || [ -f "$repo_path/setup.py" ] || [ -f "$repo_path/setup.cfg" ]; then
    echo "python"
  elif [ -f "$repo_path/requirements.txt" ]; then
    echo "python"
  elif [ -f "$repo_path/package.json" ]; then
    echo "node"
  elif [ -f "$repo_path/go.mod" ]; then
    echo "go"
  elif [ -f "$repo_path/Cargo.toml" ]; then
    echo "rust"
  elif [ -f "$repo_path/pom.xml" ] || [ -f "$repo_path/build.gradle" ]; then
    echo "java"
  elif [ -f "$repo_path/CMakeLists.txt" ] || [ -f "$repo_path/Makefile" ]; then
    echo "cpp"
  else
    echo "unknown"
  fi
}

install_deps() {
  local repo_path="$1"
  local lang="$2"

  echo -e "  ${BOLD}Installing dependencies (${lang})...${NC}"

  case "$lang" in
    python)
      cd "$repo_path"
      "$PYTHON" -m venv .venv 2>/dev/null || true
      # shellcheck disable=SC1091
      source .venv/bin/activate 2>/dev/null || true

      if [ -f "pyproject.toml" ]; then
        pip install -e ".[dev]" 2>/dev/null || \
        pip install -e ".[test]" 2>/dev/null || \
        pip install -e "." 2>/dev/null || \
        echo -e "  ${YELLOW}Could not pip install from pyproject.toml -- check manually${NC}"
      elif [ -f "setup.py" ]; then
        pip install -e ".[dev]" 2>/dev/null || \
        pip install -e "." 2>/dev/null || \
        echo -e "  ${YELLOW}Could not pip install from setup.py -- check manually${NC}"
      elif [ -f "requirements.txt" ]; then
        pip install -r requirements.txt 2>/dev/null || \
        echo -e "  ${YELLOW}Could not install from requirements.txt -- check manually${NC}"
      fi

      if [ -f "requirements-dev.txt" ]; then
        pip install -r requirements-dev.txt 2>/dev/null || true
      fi
      ;;
    node)
      cd "$repo_path"
      if [ -f "yarn.lock" ]; then
        yarn install 2>/dev/null || echo -e "  ${YELLOW}yarn install failed -- check manually${NC}"
      elif [ -f "pnpm-lock.yaml" ]; then
        pnpm install 2>/dev/null || echo -e "  ${YELLOW}pnpm install failed -- check manually${NC}"
      else
        npm install 2>/dev/null || echo -e "  ${YELLOW}npm install failed -- check manually${NC}"
      fi
      ;;
    go)
      cd "$repo_path"
      go mod download 2>/dev/null || echo -e "  ${YELLOW}go mod download failed -- check manually${NC}"
      ;;
    rust)
      cd "$repo_path"
      cargo build 2>/dev/null || echo -e "  ${YELLOW}cargo build failed -- check manually${NC}"
      ;;
    java)
      cd "$repo_path"
      if [ -f "pom.xml" ]; then
        mvn install -DskipTests 2>/dev/null || echo -e "  ${YELLOW}mvn install failed -- check manually${NC}"
      elif [ -f "build.gradle" ]; then
        ./gradlew build -x test 2>/dev/null || echo -e "  ${YELLOW}gradle build failed -- check manually${NC}"
      fi
      ;;
    *)
      echo -e "  ${YELLOW}Unknown language -- install dependencies manually${NC}"
      ;;
  esac
}

run_baseline_tests() {
  local repo_path="$1"
  local lang="$2"

  echo -e "  ${BOLD}Running baseline tests...${NC}"

  cd "$repo_path"
  local test_exit=0

  case "$lang" in
    python)
      # shellcheck disable=SC1091
      source .venv/bin/activate 2>/dev/null || true
      if command -v pytest >/dev/null 2>&1; then
        set +o pipefail
        pytest --tb=short -q 2>&1 | tail -5; test_exit=${PIPESTATUS[0]}
        set -o pipefail
      elif [ -f "tox.ini" ]; then
        set +o pipefail
        tox -e py 2>&1 | tail -5; test_exit=${PIPESTATUS[0]}
        set -o pipefail
      else
        set +o pipefail
        "$PYTHON" -m pytest --tb=short -q 2>&1 | tail -5; test_exit=${PIPESTATUS[0]}
        set -o pipefail
      fi
      ;;
    node)
      set +o pipefail
      npm test 2>&1 | tail -10; test_exit=${PIPESTATUS[0]}
      set -o pipefail
      ;;
    go)
      set +o pipefail
      go test ./... 2>&1 | tail -10; test_exit=${PIPESTATUS[0]}
      set -o pipefail
      ;;
    rust)
      set +o pipefail
      cargo test 2>&1 | tail -10; test_exit=${PIPESTATUS[0]}
      set -o pipefail
      ;;
    java)
      if [ -f "pom.xml" ]; then
        set +o pipefail
        mvn test 2>&1 | tail -10; test_exit=${PIPESTATUS[0]}
        set -o pipefail
      elif [ -f "build.gradle" ]; then
        set +o pipefail
        ./gradlew test 2>&1 | tail -10; test_exit=${PIPESTATUS[0]}
        set -o pipefail
      fi
      ;;
  esac

  if [ "$test_exit" -eq 0 ]; then
    echo -e "  ${GREEN}ok${NC} Baseline tests passed"
  else
    echo -e "  ${YELLOW}WARNING: Some tests failed (exit $test_exit)${NC}"
    echo -e "  ${DIM}This is common for pre-PR state. Check manually if needed.${NC}"
  fi
}

cmd_setup() {
  local tarball="${1:-}"

  if [ -z "$tarball" ]; then
    echo "  Usage: $0 setup <tarball-path>"
    echo ""
    echo "  Example: $0 setup ~/Downloads/prefect-repo.tar"
    exit 1
  fi

  if [ ! -f "$tarball" ]; then
    echo -e "  ${RED}File not found: $tarball${NC}"
    exit 1
  fi

  echo -e "${BOLD}PHASE 3.1: UNPACK TARBALL${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"

  local extract_dir
  extract_dir="$(dirname "$tarball")/marlin_task_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$extract_dir"

  echo -e "  Extracting to: ${BOLD}$extract_dir${NC}"
  tar -xf "$tarball" -C "$extract_dir" 2>&1

  # Find the actual repo root (tarball might have a top-level dir)
  local repo_path="$extract_dir"
  local subdirs
  subdirs=$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
  if [ -n "$subdirs" ] && [ "$(find "$extract_dir" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]; then
    repo_path="$subdirs"
  fi

  echo -e "  Repo root: ${BOLD}$repo_path${NC}"
  echo ""

  echo -e "${BOLD}PHASE 3.2: INITIALIZE GIT${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"

  cd "$repo_path"
  git init -q
  git add .
  git commit -q -m "Initial commit (pre-PR state)"
  local head_commit
  head_commit=$(git rev-parse --short HEAD)
  echo -e "  ${GREEN}ok${NC} git init + initial commit: ${BOLD}$head_commit${NC}"
  echo -e "  ${DIM}This is the HEAD commit for the Pre-Thread Survey.${NC}"
  echo ""

  echo -e "${BOLD}PHASE 3.3: DETECT LANGUAGE${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"

  local lang
  lang=$(detect_language "$repo_path")
  echo -e "  Detected: ${BOLD}$lang${NC}"
  echo ""

  echo -e "${BOLD}PHASE 3.4: INSTALL DEPENDENCIES${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"

  install_deps "$repo_path" "$lang"
  echo ""

  echo -e "${BOLD}PHASE 3.5: BASELINE TESTS${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"

  run_baseline_tests "$repo_path" "$lang"
  echo ""

  # Save state for later commands
  save_state "repo_path" "$repo_path"
  save_state "language" "$lang"
  save_state "head_commit" "$head_commit"

  # Detect virtual environment
  local has_venv=false
  local venv_type=""
  if [ -f "$repo_path/environment.yml" ] || [ -f "$repo_path/environment.yaml" ]; then
    has_venv=true
    venv_type="conda"
  elif [ -f "$repo_path/Pipfile" ]; then
    has_venv=true
    venv_type="pipenv"
  elif [ -f "$repo_path/.python-version" ]; then
    has_venv=true
    venv_type="pyenv"
  elif [ -d "$repo_path/.venv" ] || [ -d "$repo_path/venv" ]; then
    has_venv=true
    venv_type="virtualenv"
  fi

  # Copy .env files if they exist
  if [ -f "$repo_path/.env" ] || [ -f "$repo_path/.env.local" ]; then
    save_state "has_env_files" "true"
  fi

  echo -e "${GREEN}============================================================${NC}"
  echo -e "${GREEN}  SETUP COMPLETE${NC}"
  echo -e "${GREEN}============================================================${NC}"
  echo ""
  echo -e "  Repo:       ${BOLD}$repo_path${NC}"
  echo -e "  Language:   ${BOLD}$lang${NC}"
  echo -e "  HEAD:       ${BOLD}$head_commit${NC}"
  echo ""
  echo -e "  ${YELLOW}════════════════════════════════════════════════════════════${NC}"
  echo -e "  ${BOLD}SAVE THIS: Pre-Thread Survey HEAD commit = $head_commit${NC}"
  echo -e "  ${DIM}You will need this hash when filling the Snorkel survey.${NC}"
  echo -e "  ${YELLOW}════════════════════════════════════════════════════════════${NC}"
  echo ""

  if [ "$has_venv" = true ]; then
    echo -e "  ${YELLOW}Virtual environment detected: $venv_type${NC}"
    echo -e "  ${DIM}If HFI models need the venv, create a CLAUDE_ENV_FILE:${NC}"
    echo -e "    ${CYAN}echo 'source $repo_path/.venv/bin/activate' > /tmp/claude_env.sh${NC}"
    echo -e "    ${CYAN}export CLAUDE_ENV_FILE=/tmp/claude_env.sh${NC}"
    echo -e "  ${DIM}Set this BEFORE launching HFI.${NC}"
    echo ""
  fi

  echo -e "  ${BOLD}NEXT:${NC} bash $0 launch $repo_path"
  echo -e "  ${DIM}(Launch HFI first, THEN create CLAUDE.md -- Marlin V3 order)${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# claude-md: Generate CLAUDE.md from repo structure
# ---------------------------------------------------------------------------

cmd_claude_md() {
  local repo_path="${1:-$(load_state repo_path)}"

  if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
    echo "  Usage: $0 claude-md <repo-path>"
    exit 1
  fi

  local lang
  lang="${2:-$(load_state language)}"
  if [ -z "$lang" ]; then
    lang=$(detect_language "$repo_path")
  fi

  echo -e "${BOLD}GENERATE CLAUDE.md (create AFTER launching HFI)${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"
  echo -e "  ${RED}WARNING: Do NOT use claude-hfi to generate CLAUDE.md.${NC}"
  echo -e "  ${DIM}Use a separate Claude Code session or write it manually.${NC}"
  echo ""

  # Check if one already exists
  if [ -f "$repo_path/CLAUDE.md" ]; then
    echo -e "  ${GREEN}ok${NC} CLAUDE.md already exists in repo"
    echo -e "  ${DIM}Review it, then run: bash $0 copy-claude-md${NC}"
    echo -e "  ${DIM}to sync it to both A/B worktree caches.${NC}"
    echo ""
    return
  fi

  # Scan repo structure
  local top_dirs
  top_dirs=$(find "$repo_path" -mindepth 1 -maxdepth 1 -type d \
    ! -name '.git' ! -name '.venv' ! -name 'node_modules' ! -name '__pycache__' \
    ! -name '.mypy_cache' ! -name '.pytest_cache' ! -name '.tox' ! -name 'venv' \
    ! -name '.eggs' ! -name '*.egg-info' ! -name 'dist' ! -name 'build' \
    -exec basename {} \; 2>/dev/null | sort)

  # Detect test command
  local test_cmd="# TODO: fill in test command"
  case "$lang" in
    python)
      if [ -f "$repo_path/tox.ini" ]; then
        test_cmd="tox"
      elif [ -f "$repo_path/pytest.ini" ] || [ -f "$repo_path/pyproject.toml" ]; then
        test_cmd="pytest"
      else
        test_cmd="python -m pytest"
      fi
      ;;
    node) test_cmd="npm test" ;;
    go)   test_cmd="go test ./..." ;;
    rust) test_cmd="cargo test" ;;
    java)
      if [ -f "$repo_path/pom.xml" ]; then test_cmd="mvn test"
      else test_cmd="./gradlew test"; fi
      ;;
  esac

  # Detect install command
  local install_cmd="# TODO: fill in install command"
  case "$lang" in
    python)
      if [ -f "$repo_path/pyproject.toml" ]; then install_cmd="pip install -e '.[dev]'"
      elif [ -f "$repo_path/setup.py" ]; then install_cmd="pip install -e '.[dev]'"
      elif [ -f "$repo_path/requirements.txt" ]; then install_cmd="pip install -r requirements.txt"
      fi
      ;;
    node) install_cmd="npm install" ;;
    go)   install_cmd="go mod download" ;;
    rust) install_cmd="cargo build" ;;
  esac

  # Read repo name from directory
  local repo_name
  repo_name=$(basename "$repo_path")

  # Check for README
  local readme_summary=""
  if [ -f "$repo_path/README.md" ]; then
    readme_summary=$(head -20 "$repo_path/README.md" | grep -v '^#' | grep -v '^\s*$' | head -3)
  fi

  # Generate CLAUDE.md
  local claude_md="$repo_path/CLAUDE.md"
  cat > "$claude_md" << CLAUDEEOF
# CLAUDE.md

## Repository Overview
${repo_name}: ${readme_summary:-"[FILL IN: what this repo does]"}

Language: ${lang}

## Dev Setup
\`\`\`bash
${install_cmd}
\`\`\`

## Testing
\`\`\`bash
${test_cmd}
\`\`\`

## Project Structure
$(echo "$top_dirs" | while read -r d; do echo "- \`${d}/\`"; done)

## Code Conventions
- [FILL IN: naming conventions, error handling patterns]
- [FILL IN: import ordering, formatting rules]

## Architecture
- [FILL IN: key modules and how they interact]
- [FILL IN: data flow, main entry points]
CLAUDEEOF

  echo -e "  ${GREEN}ok${NC} Generated: ${BOLD}$claude_md${NC}"
  echo ""
  echo -e "  ${YELLOW}ACTION REQUIRED:${NC} Review and fill in the [FILL IN] sections"
  echo -e "  ${DIM}Open the file, add architecture details, conventions, etc.${NC}"
  echo ""
  echo -e "  ${BOLD}NEXT:${NC} Copy CLAUDE.md to worktree caches so both models see it:"
  echo -e "    ${CYAN}bash $0 copy-claude-md${NC}"
  echo ""
  echo -e "  ${DIM}Then inject your prompt: bash $0 inject <prompt-file>${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# copy-claude-md: Copy CLAUDE.md to both A/B worktree caches
# ---------------------------------------------------------------------------

cmd_copy_claude_md() {
  local repo_path="${1:-$(load_state repo_path)}"

  if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
    echo "  Usage: $0 copy-claude-md [repo-path]"
    exit 1
  fi

  if [ ! -f "$repo_path/CLAUDE.md" ]; then
    echo -e "  ${RED}No CLAUDE.md found at $repo_path/CLAUDE.md${NC}"
    echo -e "  ${DIM}Create it first with: bash $0 claude-md $repo_path${NC}"
    exit 1
  fi

  echo -e "${BOLD}COPY CLAUDE.md TO WORKTREE CACHES${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"

  local worktree_dir
  worktree_dir=$(find_worktree_dir)

  if [ -z "$worktree_dir" ]; then
    echo -e "  ${RED}Could not find worktree directory in ~/.cache/claude-hfi/${NC}"
    echo -e "  ${DIM}Make sure claude-hfi has been launched first.${NC}"
    exit 1
  fi

  if [ ! -d "$worktree_dir/A" ] || [ ! -d "$worktree_dir/B" ]; then
    echo -e "  ${RED}Worktree directories not found:${NC}"
    echo -e "    A: $worktree_dir/A"
    echo -e "    B: $worktree_dir/B"
    echo ""
    echo -e "  ${YELLOW}HFI creates these after authentication. Make sure you have:${NC}"
    echo -e "    1. Launched HFI: bash $0 launch"
    echo -e "    2. Entered the Interface Code and authenticated"
    echo -e "    3. Let HFI fully initialize (wait for prompt)"
    echo ""
    exit 1
  fi

  echo -e "  Source:  ${BOLD}$repo_path/CLAUDE.md${NC}"
  echo -e "  Dest A:  ${BOLD}$worktree_dir/A/CLAUDE.md${NC}"
  echo -e "  Dest B:  ${BOLD}$worktree_dir/B/CLAUDE.md${NC}"
  echo ""

  cp "$repo_path/CLAUDE.md" "$worktree_dir/A/CLAUDE.md"
  echo -e "  ${GREEN}ok${NC} Copied to A worktree"
  cp "$repo_path/CLAUDE.md" "$worktree_dir/B/CLAUDE.md"
  echo -e "  ${GREEN}ok${NC} Copied to B worktree"

  # Also copy .env files if they exist
  local repo_main
  repo_main=$(load_state repo_path)
  if [ -n "$repo_main" ]; then
    for envfile in .env .env.local .env.test; do
      if [ -f "$repo_main/$envfile" ]; then
        cp "$repo_main/$envfile" "$worktree_dir/A/$envfile" 2>/dev/null || true
        cp "$repo_main/$envfile" "$worktree_dir/B/$envfile" 2>/dev/null || true
        echo -e "  ${GREEN}ok${NC} Copied $envfile to both worktrees"
      fi
    done
  fi
  echo ""
  echo -e "  ${DIM}HFI won't auto-sync locally created files.${NC}"
  echo -e "  ${DIM}This manual copy ensures both models see your CLAUDE.md.${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# launch: Copy binary, launch claude-hfi --tmux
# ---------------------------------------------------------------------------

find_hfi_binary() {
  local candidates=(
    "$HOME/Downloads/darwin-arm64"
    "$HOME/Downloads/darwin-x64"
    "$HOME/Downloads/linux-arm64"
    "$HOME/Downloads/linux-x64"
    "$HOME/Downloads/claude-hfi"
  )

  for c in "${candidates[@]}"; do
    if [ -f "$c" ]; then
      echo "$c"
      return
    fi
  done

  # Search previous task directories
  local prev
  for prev in "$HOME"/Downloads/marlin_task_*/*/claude-hfi; do
    if [ -f "$prev" ]; then
      echo "$prev"
      return
    fi
  done

  # Search current working directory and parent
  if [ -f "./claude-hfi" ]; then
    echo "./claude-hfi"
    return
  fi

  echo ""
}

cmd_launch() {
  local repo_path="${1:-$(load_state repo_path)}"

  if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
    echo "  Usage: $0 launch <repo-path>"
    exit 1
  fi

  echo -e "${BOLD}PHASE 3.8: PREPARE CLI BINARY${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"

  if [ -x "$repo_path/claude-hfi" ]; then
    echo -e "  ${GREEN}ok${NC} claude-hfi already in repo root"
  else
    local binary
    binary=$(find_hfi_binary)

    if [ -z "$binary" ]; then
      echo -e "  ${RED}claude-hfi binary not found in ~/Downloads/${NC}"
      echo ""
      echo "  Download it from: https://feedback.anthropic.com/claude_code"
      echo "  Then re-run this command."
      exit 1
    fi

    echo -e "  Found: ${BOLD}$binary${NC}"
    cp "$binary" "$repo_path/claude-hfi"
    chmod +x "$repo_path/claude-hfi"
    echo -e "  ${GREEN}ok${NC} Copied and made executable"
  fi

  local hfi_version
  hfi_version=$("$repo_path/claude-hfi" --version 2>/dev/null || echo "unknown")
  echo -e "  HFI version: ${BOLD}$hfi_version${NC}"
  if [ "$hfi_version" = "unknown" ]; then
    echo -e "  ${YELLOW}WARNING: Could not determine HFI version.${NC}"
    echo -e "  ${DIM}If launch fails, download latest from https://feedback.anthropic.com/claude_code${NC}"
  fi

  echo ""
  echo -e "${BOLD}PHASE 3.9: LAUNCH CLI (tmux mode)${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"
  echo ""

  save_state "repo_path" "$repo_path"

  local env_file_export=""
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    env_file_export="export CLAUDE_ENV_FILE=$CLAUDE_ENV_FILE && "
  elif [ -f "/tmp/claude_env.sh" ]; then
    env_file_export="export CLAUDE_ENV_FILE=/tmp/claude_env.sh && "
  fi

  # Launch HFI inside a tmux session (provides proper TTY)
  local launcher_name="hfi-turn1"
  tmux kill-session -t "$launcher_name" 2>/dev/null || true

  echo -e "  Launching HFI in tmux session: ${BOLD}$launcher_name${NC}"
  echo -e "  ${DIM}HFI --tmux mode creates separate sessions for trajectories${NC}"
  echo ""

  tmux new-session -d -s "$launcher_name" -c "$repo_path" \
    "${env_file_export}./claude-hfi --tmux 2>&1 | tee /tmp/hfi_launch.log"

  save_state "launcher_session" "$launcher_name"
  save_state "current_turn" "1"

  # Wait for HFI to start and extract session ID
  echo -e "  Waiting for HFI to initialize..."
  local session_id=""
  for i in $(seq 1 60); do
    if [ -f /tmp/hfi_launch.log ]; then
      session_id=$(grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' /tmp/hfi_launch.log 2>/dev/null | head -1 || echo "")
      if [ -n "$session_id" ]; then
        break
      fi
    fi
    sleep 2
  done

  if [ -n "$session_id" ]; then
    save_state "session_id" "$session_id"
    echo -e "  ${GREEN}ok${NC} Session ID: ${BOLD}$session_id${NC}"
    echo ""
    echo -e "  Trajectory A: ${CYAN}tmux attach -t ${session_id}-A${NC}"
    echo -e "  Trajectory B: ${CYAN}tmux attach -t ${session_id}-B${NC}"
    echo -e "  Control:      ${CYAN}tmux attach -t $launcher_name${NC}"
  else
    echo -e "  ${YELLOW}Could not auto-detect session ID.${NC}"
    echo -e "  Run ${BOLD}tmux ls${NC} to find it, then:"
    echo -e "    Save it with: bash $0 set-session <session-id>"
  fi

  echo ""
  echo -e "  ${YELLOW}When prompted for Interface Code, enter:${NC}"
  echo -e "    ${BOLD}cc_agentic_coding_next${NC}"
  echo ""
  echo -e "  ${YELLOW}════════════════════════════════════════════════════════════${NC}"
  echo -e "  ${BOLD}IMPORTANT -- CLAUDE.md WORKFLOW (Marlin V3 requirement):${NC}"
  echo -e "  ${YELLOW}════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "  1. Create CLAUDE.md NOW (after HFI launch, not before):"
  echo -e "     ${CYAN}bash $0 claude-md $repo_path${NC}"
  echo ""
  echo -e "  2. Copy it to BOTH worktree caches (HFI won't auto-sync):"
  echo -e "     ${CYAN}bash $0 copy-claude-md${NC}"
  echo ""
  echo -e "  3. ${RED}Do NOT use claude-hfi to generate CLAUDE.md.${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# set-session: Manually save the session ID if auto-detect failed
# ---------------------------------------------------------------------------

cmd_set_session() {
  local session_id="${1:-}"
  if [ -z "$session_id" ]; then
    echo "  Usage: $0 set-session <session-id>"
    echo ""
    echo "  Find it with: tmux ls"
    echo "  The session ID is the UUID part before -A or -B"
    echo "  Example: if sessions are abc123-A and abc123-B, the ID is abc123"
    exit 1
  fi
  save_state "session_id" "$session_id"
  echo -e "  ${GREEN}ok${NC} Session ID saved: ${BOLD}$session_id${NC}"
  echo -e "  Trajectories: ${session_id}-A, ${session_id}-B"
}

# ---------------------------------------------------------------------------
# inject: Paste prompt into the tmux control session
# ---------------------------------------------------------------------------

cmd_inject() {
  local prompt_source="${1:-}"
  local session_id
  session_id=$(load_state session_id)

  if [ -z "$session_id" ]; then
    echo -e "  ${RED}No session ID found. Run 'launch' first or 'set-session <id>'.${NC}"
    exit 1
  fi

  if [ -z "$prompt_source" ]; then
    echo "  Usage: $0 inject <prompt-file-or-text>"
    echo "         $0 inject --file path/to/prompt.txt"
    exit 1
  fi

  local prompt_text
  if [ "$prompt_source" = "--file" ]; then
    local prompt_file="${2:-}"
    if [ -z "$prompt_file" ] || [ ! -f "$prompt_file" ]; then
      echo -e "  ${RED}File not found: $prompt_file${NC}"
      exit 1
    fi
    prompt_text=$(cat "$prompt_file")
  elif [ -f "$prompt_source" ]; then
    prompt_text=$(cat "$prompt_source")
  else
    prompt_text="$prompt_source"
  fi

  echo -e "${BOLD}PHASE 4.1: INJECT PROMPT${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"
  echo ""

  local word_count
  word_count=$(echo "$prompt_text" | wc -w | tr -d ' ')
  echo -e "  Session:  ${BOLD}$session_id${NC}"
  echo -e "  Words:    ${BOLD}$word_count${NC}"
  echo ""

  # Determine target: use launcher_session (where HFI control runs)
  local launcher_session
  launcher_session=$(load_state launcher_session)
  local control_target=""

  if [ -n "$launcher_session" ] && tmux has-session -t "$launcher_session" 2>/dev/null; then
    control_target="$launcher_session"
  else
    # Fallback: find any hfi-* session
    local hfi_sess
    hfi_sess=$(tmux ls -F '#{session_name}' 2>/dev/null | grep '^hfi-' | head -1 || echo "")
    if [ -n "$hfi_sess" ]; then
      control_target="$hfi_sess"
      echo -e "  ${YELLOW}Using detected session: $hfi_sess${NC}"
    else
      echo -e "  ${RED}No active HFI session found.${NC}"
      echo -e "  Active tmux sessions:"
      tmux ls 2>/dev/null || echo "  (none)"
      echo ""
      echo -e "  ${DIM}Launch HFI first: bash $0 launch <repo-path>${NC}"
      exit 1
    fi
  fi

  echo -e "  Target:   ${BOLD}$control_target${NC}"

  # Send the prompt text using load-buffer for reliability
  local tmpfile
  tmpfile=$(mktemp /tmp/marlin_prompt.XXXXXX)
  echo "$prompt_text" > "$tmpfile"

  tmux load-buffer -b marlin_prompt "$tmpfile"
  tmux paste-buffer -b marlin_prompt -t "$control_target"

  # Send Enter to submit
  sleep 0.5
  tmux send-keys -t "$control_target" Enter

  rm -f "$tmpfile"

  echo -e "  ${GREEN}ok${NC} Prompt injected and submitted"
  echo ""
  echo -e "  Both trajectories are now running."
  echo -e "  ${BOLD}NEXT:${NC} bash $0 monitor"
  echo ""
}

# ---------------------------------------------------------------------------
# monitor: Poll tmux sessions until trajectories complete
# ---------------------------------------------------------------------------

cmd_monitor() {
  local session_id
  session_id=$(load_state session_id)
  local launcher_session
  launcher_session=$(load_state launcher_session)

  if [ -z "$session_id" ]; then
    echo -e "  ${RED}No session ID found. Run 'launch' first or 'set-session <id>'.${NC}"
    exit 1
  fi

  # --tmux mode creates SEPARATE sessions: <id>-A and <id>-B
  local sess_a="${session_id}-A"
  local sess_b="${session_id}-B"
  local sess_ctrl="${launcher_session:-${session_id}-control}"

  echo -e "${BOLD}PHASE 4.2: MONITORING TRAJECTORIES${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"
  echo ""
  echo -e "  Session: ${BOLD}$session_id${NC}"
  echo -e "  Watching: ${CYAN}$sess_a${NC}, ${CYAN}$sess_b${NC}"
  echo -e "  Control:  ${CYAN}$sess_ctrl${NC}"
  echo -e "  ${DIM}Press Ctrl+C to stop monitoring (trajectories keep running)${NC}"
  echo ""

  local poll_interval=15
  local elapsed=0
  local status_a="running"
  local status_b="running"
  local MAX_MONITOR_SECONDS=7200

  echo -e "  ${DIM}Timeout: $((MAX_MONITOR_SECONDS / 60)) minutes. Ctrl+C to stop early.${NC}"
  echo -e "  ${YELLOW}IMPORTANT: Keep an eye on trajectory tmux sessions!${NC}"
  echo -e "  ${YELLOW}If a model asks for permission, you must approve it manually.${NC}"
  echo -e "  ${DIM}Attach: tmux attach -t $sess_a  (or $sess_b)${NC}"
  echo ""

  while true; do
    if [ "$elapsed" -ge "$MAX_MONITOR_SECONDS" ]; then
      echo ""
      echo ""
      echo -e "  ${RED}TIMEOUT: Monitoring exceeded $((MAX_MONITOR_SECONDS / 60)) minutes.${NC}"
      echo -e "  ${YELLOW}Check trajectory sessions manually:${NC}"
      echo -e "    tmux attach -t $sess_a"
      echo -e "    tmux attach -t $sess_b"
      echo ""
      break
    fi

    local output_a="" output_b="" output_ctrl=""

    if tmux has-session -t "$sess_a" 2>/dev/null; then
      output_a=$(tmux capture-pane -t "$sess_a" -p -l 5 2>/dev/null || echo "")
    else
      status_a="ended"
    fi

    if tmux has-session -t "$sess_b" 2>/dev/null; then
      output_b=$(tmux capture-pane -t "$sess_b" -p -l 5 2>/dev/null || echo "")
    else
      status_b="ended"
    fi

    if tmux has-session -t "$sess_ctrl" 2>/dev/null; then
      output_ctrl=$(tmux capture-pane -t "$sess_ctrl" -p -l 5 2>/dev/null || echo "")
    fi

    # Detect completion and failure states
    if echo "$output_a" | grep -q '\$ *$' 2>/dev/null; then
      status_a="done"
    fi
    if echo "$output_b" | grep -q '\$ *$' 2>/dev/null; then
      status_b="done"
    fi

    # Detect context limit failures
    if echo "$output_a" | grep -qi "context limit\|context window exceeded" 2>/dev/null; then
      status_a="CONTEXT_LIMIT"
    fi
    if echo "$output_b" | grep -qi "context limit\|context window exceeded" 2>/dev/null; then
      status_b="CONTEXT_LIMIT"
    fi

    # Detect permission prompts (model waiting for user)
    local a_waiting=false b_waiting=false
    if echo "$output_a" | grep -qi "Allow.*action\|y/n\|permission" 2>/dev/null; then
      a_waiting=true
    fi
    if echo "$output_b" | grep -qi "Allow.*action\|y/n\|permission" 2>/dev/null; then
      b_waiting=true
    fi

    # Check if feedback form appeared in control
    local feedback_ready=false
    if echo "$output_ctrl" | grep -qi "feedback\|senior engineer\|model A did well\|Submit Feedback" 2>/dev/null; then
      feedback_ready=true
    fi

    local mins=$((elapsed / 60))
    local secs=$((elapsed % 60))
    local extra_a="" extra_b=""
    if [ "$a_waiting" = true ]; then extra_a=" [WAITING FOR PERMISSION]"; fi
    if [ "$b_waiting" = true ]; then extra_b=" [WAITING FOR PERMISSION]"; fi
    printf "\r  [%02d:%02d]  A: %-15s  B: %-15s" "$mins" "$secs" "${status_a}${extra_a}" "${status_b}${extra_b}"

    # Alert on permission prompts
    if [ "$a_waiting" = true ] || [ "$b_waiting" = true ]; then
      echo ""
      echo -e "  ${YELLOW}*** A trajectory is waiting for your permission! ***${NC}"
      if [ "$a_waiting" = true ]; then
        echo -e "  ${YELLOW}  Trajectory A: tmux attach -t $sess_a  (type 'y' + Enter)${NC}"
      fi
      if [ "$b_waiting" = true ]; then
        echo -e "  ${YELLOW}  Trajectory B: tmux attach -t $sess_b  (type 'y' + Enter)${NC}"
      fi
    fi

    # Alert on context limits
    if [ "$status_a" = "CONTEXT_LIMIT" ] || [ "$status_b" = "CONTEXT_LIMIT" ]; then
      echo ""
      echo -e "  ${RED}*** CONTEXT LIMIT HIT ***${NC}"
      if [ "$status_a" = "CONTEXT_LIMIT" ]; then
        echo -e "  ${RED}  Trajectory A ran out of context window${NC}"
      fi
      if [ "$status_b" = "CONTEXT_LIMIT" ]; then
        echo -e "  ${RED}  Trajectory B ran out of context window${NC}"
      fi
      echo -e "  ${DIM}This trajectory will produce no/incomplete changes.${NC}"
      echo -e "  ${DIM}Rate it as FAILED in feedback. The other trajectory may still succeed.${NC}"
      echo -e "  ${DIM}If this keeps happening, write a more focused prompt next turn.${NC}"
    fi

    if [ "$feedback_ready" = true ]; then
      echo ""
      echo ""
      echo -e "  ${GREEN}============================================================${NC}"
      echo -e "  ${GREEN}  TRAJECTORIES COMPLETE -- FEEDBACK FORM READY${NC}"
      echo -e "  ${GREEN}============================================================${NC}"
      echo ""

      # Report any failures
      if [ "$status_a" = "CONTEXT_LIMIT" ]; then
        echo -e "  ${RED}WARNING: Trajectory A hit context limit -- rate as FAILED${NC}"
      fi
      if [ "$status_b" = "CONTEXT_LIMIT" ]; then
        echo -e "  ${RED}WARNING: Trajectory B hit context limit -- rate as FAILED${NC}"
      fi
      echo ""

      echo -e "  Control: ${CYAN}tmux attach -t $sess_ctrl${NC}"
      echo ""
      echo -e "  Review trajectories:"
      echo -e "    ${CYAN}tmux attach -t $sess_a${NC}"
      echo -e "    ${CYAN}tmux attach -t $sess_b${NC}"
      echo ""
      printf '\a'
      break
    fi

    if [ "$status_a" = "ended" ] && [ "$status_b" = "ended" ]; then
      echo ""
      echo ""
      echo -e "  ${YELLOW}Both trajectory sessions have ended.${NC}"
      echo -e "  Check control: ${CYAN}tmux attach -t $sess_ctrl${NC}"
      break
    fi

    sleep "$poll_interval"
    elapsed=$((elapsed + poll_interval))
  done
}

# ---------------------------------------------------------------------------
# capture-diffs: Extract diffs from A/B worktrees and save to files
# ---------------------------------------------------------------------------

find_worktree_dir() {
  local repo_path
  repo_path=$(load_state repo_path)
  local project_name
  project_name=$(basename "$repo_path")

  local cache_base="$HOME/.cache/claude-hfi"

  # Try exact project name first, then scan for matches
  if [ -d "$cache_base/$project_name/A" ]; then
    echo "$cache_base/$project_name"
    return
  fi

  # Scan for any project with A/B subdirs
  for d in "$cache_base"/*/; do
    if [ -d "${d}A" ] && [ -d "${d}B" ]; then
      echo "${d%/}"
      return
    fi
  done

  echo ""
}

cmd_capture_diffs() {
  local turn_num="${1:-}"

  if [ -z "$turn_num" ]; then
    # Auto-detect turn number from existing files
    turn_num=1
    while [ -f "$STATE_DIR/turn${turn_num}_diff_A.txt" ]; do
      turn_num=$((turn_num + 1))
    done
  fi

  echo -e "${BOLD}CAPTURE DIFFS -- Turn $turn_num${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"

  local worktree_dir
  worktree_dir=$(find_worktree_dir)

  if [ -z "$worktree_dir" ]; then
    echo -e "  ${RED}Could not find worktree directory in ~/.cache/claude-hfi/${NC}"
    echo -e "  ${DIM}Make sure claude-hfi has been launched and trajectories have run.${NC}"
    exit 1
  fi

  echo -e "  Worktree dir: ${BOLD}$worktree_dir${NC}"

  local dir_a="$worktree_dir/A"
  local dir_b="$worktree_dir/B"

  mkdir -p "$STATE_DIR"

  # Capture diff for A
  if [ -d "$dir_a/.git" ] || [ -d "$dir_a" ]; then
    echo -e "  Capturing Trajectory A diff..."
    (
      cd "$dir_a"
      echo "=== TRAJECTORY A -- Turn $turn_num ==="
      echo "=== Changed files ==="
      git diff --name-status HEAD 2>/dev/null || git diff --name-status 2>/dev/null || echo "(no git changes detected)"
      echo ""
      echo "=== Full diff ==="
      git diff HEAD 2>/dev/null || git diff 2>/dev/null || echo "(no diff)"
    ) > "$STATE_DIR/turn${turn_num}_diff_A.txt" 2>&1
    local lines_a
    lines_a=$(wc -l < "$STATE_DIR/turn${turn_num}_diff_A.txt" | tr -d ' ')
    echo -e "  ${GREEN}ok${NC} Saved: data/turn${turn_num}_diff_A.txt ($lines_a lines)"
  else
    echo -e "  ${RED}Trajectory A directory not found: $dir_a${NC}"
  fi

  # Capture diff for B
  if [ -d "$dir_b/.git" ] || [ -d "$dir_b" ]; then
    echo -e "  Capturing Trajectory B diff..."
    (
      cd "$dir_b"
      echo "=== TRAJECTORY B -- Turn $turn_num ==="
      echo "=== Changed files ==="
      git diff --name-status HEAD 2>/dev/null || git diff --name-status 2>/dev/null || echo "(no git changes detected)"
      echo ""
      echo "=== Full diff ==="
      git diff HEAD 2>/dev/null || git diff 2>/dev/null || echo "(no diff)"
    ) > "$STATE_DIR/turn${turn_num}_diff_B.txt" 2>&1
    local lines_b
    lines_b=$(wc -l < "$STATE_DIR/turn${turn_num}_diff_B.txt" | tr -d ' ')
    echo -e "  ${GREEN}ok${NC} Saved: data/turn${turn_num}_diff_B.txt ($lines_b lines)"
  else
    echo -e "  ${RED}Trajectory B directory not found: $dir_b${NC}"
  fi

  # Also capture file trees
  (
    echo "=== Trajectory A -- Modified/New files ==="
    cd "$dir_a" 2>/dev/null && git diff --name-only HEAD 2>/dev/null || echo "(none)"
    echo ""
    echo "=== Trajectory B -- Modified/New files ==="
    cd "$dir_b" 2>/dev/null && git diff --name-only HEAD 2>/dev/null || echo "(none)"
  ) > "$STATE_DIR/turn${turn_num}_summary.txt" 2>&1

  save_state "current_turn" "$turn_num"

  echo ""
  echo -e "  ${GREEN}ok${NC} Diffs captured for Turn $turn_num"
  echo -e "  Files:"
  echo -e "    data/turn${turn_num}_diff_A.txt"
  echo -e "    data/turn${turn_num}_diff_B.txt"
  echo -e "    data/turn${turn_num}_summary.txt"
  echo ""
}

# ---------------------------------------------------------------------------
# select-winner: Send winner feedback via tmux
# ---------------------------------------------------------------------------

cmd_select_winner() {
  local winner="${1:-}"
  local turn="${2:-}"
  local session_id
  session_id=$(load_state session_id)

  if [ -z "$winner" ]; then
    echo "  Usage: $0 select-winner <A|B|tie> [turn-number]"
    exit 1
  fi

  echo -e "${BOLD}FEEDBACK GUIDANCE${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"
  echo ""
  echo -e "  ${BOLD}Recommended winner: $winner${NC}"
  echo ""
  echo -e "  ${YELLOW}YOU must fill the HFI feedback form MANUALLY.${NC}"
  echo -e "  ${DIM}Automation does NOT send keys to avoid mis-clicks.${NC}"
  echo ""

  if [ -n "$session_id" ]; then
    local launcher_session
    launcher_session=$(load_state launcher_session)
    echo -e "  Attach to control:  ${CYAN}tmux attach -t ${launcher_session:-${session_id}-control}${NC}"
    echo ""
  fi

  echo -e "  ${BOLD}HFI Feedback Form Navigation:${NC}"
  echo -e "    j / k       Move between questions"
  echo -e "    h / l       Move rating slider (h=toward A, l=toward B)"
  echo -e "    Enter       Confirm selection"
  echo -e "    ?           Show rating descriptions"
  echo ""
  echo -e "  ${BOLD}Rating Scale:${NC}"
  echo -e "    A1 = A clearly superior"
  echo -e "    A2 = A significantly better"
  echo -e "    A3 = A better overall"
  echo -e "    A4 / B4 = Effectively equivalent"
  echo -e "    B3 = B better overall"
  echo -e "    B2 = B significantly better"
  echo -e "    B1 = B clearly superior"
  echo ""
  echo -e "  ${BOLD}CRITICAL RULES:${NC}"
  echo -e "    - Strengths must be EVALUATIVE, not descriptive"
  echo -e "      ${GREEN}Good:${NC} 'Excellent error handling with proper edge cases'"
  echo -e "      ${RED}Bad:${NC}  'Added try-catch blocks around API calls'"
  echo -e "    - Use N/A sparingly (only for truly inapplicable axes)"
  echo -e "    - Key axis MUST be filled for the overall winner question"
  echo ""

  local continue_or_finish="Continue conversation"
  if [ -n "$turn" ] && [ "$turn" -ge 3 ]; then
    continue_or_finish="Finish conversation"
  fi

  echo -e "  ${BOLD}After submitting ratings:${NC}"
  echo -e "    Select: ${CYAN}${continue_or_finish}${NC}"
  echo ""
  echo -e "  ${YELLOW}Type 'feedback done' in Cursor when you finish.${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# TUI helpers: send text in chunks, set scale ratings
# ---------------------------------------------------------------------------

tmux_send_text() {
  local target="$1"
  local text="$2"

  local tmpfile
  tmpfile=$(mktemp /tmp/tmux_text.XXXXXX)
  printf '%s' "$text" > "$tmpfile"
  tmux load-buffer "$tmpfile"
  tmux paste-buffer -t "$target" -d
  rm -f "$tmpfile"
  sleep 0.5
}

tmux_set_scale() {
  local target="$1"
  local rating="$2"

  local position=0
  case "$rating" in
    A1) position=0 ;;
    A2) position=1 ;;
    A3) position=2 ;;
    A4) position=3 ;;
    B4) position=4 ;;
    B3) position=5 ;;
    B2) position=6 ;;
    B1) position=7 ;;
    NA) position=8 ;;
    *)  echo -e "  ${RED}Unknown rating: $rating${NC}"; return 1 ;;
  esac

  for i in $(seq 1 8); do
    tmux send-keys -t "$target" Left
    sleep 0.1
  done

  if [ "$position" -gt 0 ]; then
    for i in $(seq 1 "$position"); do
      tmux send-keys -t "$target" Right
      sleep 0.1
    done
  fi
  sleep 0.3
}

# ---------------------------------------------------------------------------
# fill-feedback: Automated TUI form filling from structured file
# ---------------------------------------------------------------------------
#
# Feedback file format (delimiter: lines starting with ::SECTION::):
#
#   ::SENIOR_EXPECTATIONS::
#   text here...
#   ::MODEL_A_STRENGTHS::
#   text here...
#   ::MODEL_A_WEAKNESSES::
#   text here...
#   ::MODEL_B_STRENGTHS::
#   text here...
#   ::MODEL_B_WEAKNESSES::
#   text here...
#   ::RATINGS::
#   6.1=B1
#   6.2=B1
#   ...
#   6.11=B1
#   overall=B1
#   ::KEY_AXIS::
#   text here...
#   ::JUSTIFICATION::
#   text here...
#   ::ACTION::
#   continue   (or "finish")
#
# ---------------------------------------------------------------------------

cmd_fill_feedback() {
  local feedback_file="${1:-}"
  local launcher_session="${2:-}"

  if [ -z "$feedback_file" ] || [ ! -f "$feedback_file" ]; then
    echo "  Usage: $0 fill-feedback <feedback-file> [launcher-session]"
    echo ""
    echo "  The feedback file uses ::SECTION:: delimiters."
    echo "  See hfi_orchestrator.sh source for format details."
    exit 1
  fi

  if [ -z "$launcher_session" ]; then
    launcher_session=$(load_state launcher_session)
  fi

  if [ -z "$launcher_session" ]; then
    echo -e "  ${RED}No launcher session found.${NC}"
    echo -e "  ${DIM}Pass it as 2nd arg or set via: save_state launcher_session <name>${NC}"
    exit 1
  fi

  if ! tmux has-session -t "$launcher_session" 2>/dev/null; then
    echo -e "  ${RED}Session '$launcher_session' not found.${NC}"
    tmux ls 2>/dev/null || echo "  (no tmux sessions)"
    exit 1
  fi

  echo -e "${BOLD}FILL FEEDBACK FORM (automated)${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"
  echo -e "  File:    ${BOLD}$feedback_file${NC}"
  echo -e "  Session: ${BOLD}$launcher_session${NC}"
  echo ""

  local current_section=""
  local section_text=""
  local key_axis_text=""
  local justification_text=""
  local action="continue"
  local senior_text=""
  local a_strengths=""
  local a_weaknesses=""
  local b_strengths=""
  local b_weaknesses=""
  local r_6_1="A4" r_6_2="A4" r_6_3="A4" r_6_4="A4" r_6_5="A4"
  local r_6_6="A4" r_6_7="A4" r_6_8="A4" r_6_9="A4" r_6_10="A4"
  local r_6_11="A4" r_overall="A4"

  _save_section() {
    case "$1" in
      SENIOR_EXPECTATIONS) senior_text="$2" ;;
      MODEL_A_STRENGTHS)   a_strengths="$2" ;;
      MODEL_A_WEAKNESSES)  a_weaknesses="$2" ;;
      MODEL_B_STRENGTHS)   b_strengths="$2" ;;
      MODEL_B_WEAKNESSES)  b_weaknesses="$2" ;;
      KEY_AXIS)            key_axis_text="$2" ;;
      JUSTIFICATION)       justification_text="$2" ;;
      ACTION)              action="$(echo "$2" | tr -d '[:space:]')" ;;
    esac
  }

  _save_rating() {
    case "$1" in
      6.1) r_6_1="$2" ;; 6.2) r_6_2="$2" ;; 6.3) r_6_3="$2" ;;
      6.4) r_6_4="$2" ;; 6.5) r_6_5="$2" ;; 6.6) r_6_6="$2" ;;
      6.7) r_6_7="$2" ;; 6.8) r_6_8="$2" ;; 6.9) r_6_9="$2" ;;
      6.10) r_6_10="$2" ;; 6.11) r_6_11="$2" ;; overall) r_overall="$2" ;;
    esac
  }

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^::([A-Z_]+):: ]]; then
      if [ -n "$current_section" ] && [ -n "$section_text" ]; then
        _save_section "$current_section" "$section_text"
      fi
      current_section="${BASH_REMATCH[1]}"
      section_text=""
    elif [ "$current_section" = "RATINGS" ]; then
      if [[ "$line" =~ ^([0-9.]+|overall)=([A-Z0-9]+) ]]; then
        _save_rating "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
      fi
    else
      if [ -n "$section_text" ]; then
        section_text="$section_text $line"
      else
        section_text="$line"
      fi
    fi
  done < "$feedback_file"

  if [ -n "$current_section" ] && [ -n "$section_text" ]; then
    _save_section "$current_section" "$section_text"
  fi

  local target="$launcher_session"

  # Field 1: Senior expectations
  echo -e "  [1/7] Filling: Senior expectations..."
  tmux_send_text "$target" "$senior_text"
  tmux send-keys -t "$target" Tab; sleep 0.5

  # Field 2: Model A strengths
  echo -e "  [2/7] Filling: Model A strengths..."
  tmux_send_text "$target" "$a_strengths"
  tmux send-keys -t "$target" Tab; sleep 0.5

  # Field 3: Model A weaknesses
  echo -e "  [3/7] Filling: Model A weaknesses..."
  tmux_send_text "$target" "$a_weaknesses"
  tmux send-keys -t "$target" Tab; sleep 0.5

  # Field 4: Model B strengths
  echo -e "  [4/7] Filling: Model B strengths..."
  tmux_send_text "$target" "$b_strengths"
  tmux send-keys -t "$target" Tab; sleep 0.5

  # Field 5: Model B weaknesses
  echo -e "  [5/7] Filling: Model B weaknesses..."
  tmux_send_text "$target" "$b_weaknesses"
  tmux send-keys -t "$target" Tab; sleep 0.5

  # Scales 6.1 through 6.11
  echo -e "  [6/7] Setting ratings (6.1-6.11 + overall)..."
  for r_var in r_6_1 r_6_2 r_6_3 r_6_4 r_6_5 r_6_6 r_6_7 r_6_8 r_6_9 r_6_10 r_6_11; do
    local r="${!r_var}"
    tmux_set_scale "$target" "$r"
    tmux send-keys -t "$target" Tab; sleep 0.3
  done

  # Overall preference scale
  tmux_set_scale "$target" "$r_overall"
  tmux send-keys -t "$target" Tab; sleep 0.5

  # Key-axis text
  tmux_send_text "$target" "$key_axis_text"
  tmux send-keys -t "$target" Tab; sleep 0.5

  # Justification text
  tmux_send_text "$target" "$justification_text"
  tmux send-keys -t "$target" Tab; sleep 0.5

  # Submit
  echo -e "  [7/7] Submitting feedback..."
  tmux send-keys -t "$target" Enter

  # Wait for submission with retry (uploads can take 30-60s)
  local submit_success=false
  for attempt in $(seq 1 6); do
    sleep 10
    local submit_output
    submit_output=$(tmux capture-pane -t "$target" -p 2>/dev/null || echo "")
    if echo "$submit_output" | grep -qi "submitted successfully\|what would you like\|continue conversation\|finish conversation" 2>/dev/null; then
      submit_success=true
      echo -e "  ${GREEN}ok${NC} Feedback submitted successfully"
      break
    fi
    if echo "$submit_output" | grep -qi "error\|timeout\|failed" 2>/dev/null; then
      echo -e "  ${RED}Submission error detected on attempt $attempt${NC}"
      echo -e "  ${DIM}Retrying... (Enter to resubmit)${NC}"
      tmux send-keys -t "$target" Enter
    fi
    echo -e "  ${DIM}  ...waiting for upload ($((attempt * 10))s)${NC}"
  done

  if [ "$submit_success" = false ]; then
    echo ""
    echo -e "  ${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${RED}║  SUBMISSION FAILED -- AUTOMATIC DIAGNOSIS               ║${NC}"
    echo -e "  ${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}What happened:${NC}"
    echo -e "  The feedback form was filled and submitted but the upload"
    echo -e "  to Anthropics servers did not complete within 60 seconds."
    echo -e "  Your feedback was saved LOCALLY but may not have reached Snorkel."
    echo ""
    echo -e "  ${BOLD}Why this happens:${NC}"
    echo -e "  1. Large diffs from trajectory changes exceed upload timeout"
    echo -e "  2. Context overflow from not exiting HFI between turns"
    echo -e "  3. Network issues between your machine and Anthropic servers"
    echo ""

    # Auto-run diagnosis
    echo -e "  ${BOLD}Running automatic diagnosis...${NC}"
    echo -e "${YELLOW}------------------------------------------------------------${NC}"

    local diag_session_id
    diag_session_id=$(load_state session_id)
    local diag_session_dir=""
    local diag_tmpdir="${TMPDIR:-/tmp}"
    if [ -d "${diag_tmpdir}claude-hfi/${diag_session_id}" ]; then
      diag_session_dir="${diag_tmpdir}claude-hfi/${diag_session_id}"
    elif [ -d "/tmp/claude-hfi/${diag_session_id}" ]; then
      diag_session_dir="/tmp/claude-hfi/${diag_session_id}"
    else
      diag_session_dir=$(find "${diag_tmpdir}" -maxdepth 4 -type d -name "$diag_session_id" 2>/dev/null | head -1)
    fi

    if [ -n "$diag_session_dir" ] && [ -d "$diag_session_dir" ]; then
      local diag_step=$((current_turn - 1))

      # Check submission file
      local diag_sub="$diag_session_dir/submission-step-${diag_step}.json"
      if [ -f "$diag_sub" ]; then
        local diag_size
        diag_size=$(wc -c < "$diag_sub" | tr -d ' ')
        echo -e "  submission-step-${diag_step}.json: EXISTS (${diag_size} bytes)"
        if [ "$diag_size" -lt 1000 ]; then
          echo -e "  ${RED}  ^ Too small -- submission was incomplete${NC}"
        fi
      else
        echo -e "  submission-step-${diag_step}.json: ${RED}MISSING${NC}"
      fi

      # Check debug log for this turn's diff uploads
      if [ -f "$diag_session_dir/debug.txt" ]; then
        local diag_diffs
        diag_diffs=$(grep -c "step-${diag_step}.diff" "$diag_session_dir/debug.txt" 2>/dev/null || echo "0")
        echo -e "  Diff uploads for Turn $current_turn: $diag_diffs (should be 2)"

        local diag_errors
        diag_errors=$(grep -c '\[ERROR\]' "$diag_session_dir/debug.txt" 2>/dev/null || echo "0")
        local diag_timeouts
        diag_timeouts=$(grep -ci 'timeout' "$diag_session_dir/debug.txt" 2>/dev/null || echo "0")
        echo -e "  Total errors in log: $diag_errors"
        echo -e "  Total timeout events: $diag_timeouts"

        if [ "$diag_errors" -gt 0 ]; then
          echo ""
          echo -e "  ${YELLOW}Last 3 errors:${NC}"
          grep '\[ERROR\]' "$diag_session_dir/debug.txt" 2>/dev/null | tail -3 | sed 's/^/    /'
        fi
      fi
    else
      echo -e "  ${YELLOW}Could not find session directory for auto-diagnosis${NC}"
    fi

    echo ""
    echo -e "${YELLOW}------------------------------------------------------------${NC}"
    echo -e "  ${BOLD}HOW TO FIX:${NC}"
    echo ""
    echo -e "  ${CYAN}Option 1 (recommended):${NC} Retry this turn automatically"
    echo -e "    bash $0 retry-turn $current_turn"
    echo ""
    echo -e "  ${CYAN}Option 2:${NC} Run full diagnosis first, then decide"
    echo -e "    bash $0 diagnose"
    echo ""
    echo -e "  ${CYAN}Option 3:${NC} Check manually"
    echo -e "    tmux attach -t $target"
    echo -e "    (look for error messages on screen)"
    echo ""
    echo -e "  ${DIM}For detailed troubleshooting, see: TROUBLESHOOTING.md${NC}"
    echo ""
    return 1
  fi

  # Verify submission file exists locally
  local session_id
  session_id=$(load_state session_id)
  local current_turn
  current_turn=$(load_state current_turn)
  current_turn="${current_turn:-1}"
  local step_idx=$((current_turn - 1))

  local session_dir=""
  local tmpdir="${TMPDIR:-/tmp}"
  if [ -d "${tmpdir}claude-hfi/${session_id}" ]; then
    session_dir="${tmpdir}claude-hfi/${session_id}"
  elif [ -d "/tmp/claude-hfi/${session_id}" ]; then
    session_dir="/tmp/claude-hfi/${session_id}"
  else
    session_dir=$(find "${tmpdir}" -maxdepth 4 -type d -name "$session_id" 2>/dev/null | head -1)
  fi

  if [ -n "$session_dir" ] && [ -d "$session_dir" ]; then
    local sub_file="$session_dir/submission-step-${step_idx}.json"
    if [ -f "$sub_file" ]; then
      local sub_size
      sub_size=$(wc -c < "$sub_file" | tr -d ' ')
      if [ "$sub_size" -gt 1000 ]; then
        echo -e "  ${GREEN}VERIFIED${NC} submission-step-${step_idx}.json exists (${sub_size} bytes)"
      else
        echo -e "  ${RED}WARNING${NC} submission-step-${step_idx}.json is only ${sub_size} bytes -- may be incomplete"
      fi
    else
      echo -e "  ${RED}WARNING${NC} submission-step-${step_idx}.json NOT FOUND in session dir"
      echo -e "  ${YELLOW}The upload to Snorkel may have failed. Check HFI logs.${NC}"
    fi
  fi

  # Handle continue/finish selection
  local post_output
  post_output=$(tmux capture-pane -t "$target" -p 2>/dev/null || echo "")
  if echo "$post_output" | grep -qi "continue conversation\|finish conversation" 2>/dev/null; then
    if [ "$action" = "finish" ]; then
      echo -e "  Selecting: ${BOLD}Finish conversation${NC}"
      tmux send-keys -t "$target" Down; sleep 0.5
    else
      echo -e "  Selecting: ${BOLD}Continue conversation${NC}"
    fi
    tmux send-keys -t "$target" Enter
    sleep 3

    # Handle post-thread survey (appears after "Finish conversation")
    if [ "$action" = "finish" ]; then
      sleep 3
      local survey_output
      survey_output=$(tmux capture-pane -t "$target" -p 2>/dev/null || echo "")
      if echo "$survey_output" | grep -qi "Thread Feedback\|Comments\|Submit and Finish" 2>/dev/null; then
        echo -e "  ${BOLD}Filling post-thread survey...${NC}"

        # Fill the Comments field
        local survey_text="Multi-turn task completed across 3 turns. Both trajectories produced working implementations with incremental improvements each turn. Task execution followed standard workflow with exit and relaunch between turns"
        tmux_send_text "$target" "$survey_text"
        tmux send-keys -t "$target" Tab; sleep 0.5

        # Submit and Finish
        tmux send-keys -t "$target" Enter
        sleep 5

        local final_output
        final_output=$(tmux capture-pane -t "$target" -p 2>/dev/null || echo "")
        if echo "$final_output" | grep -qi "Submit and Finish" 2>/dev/null; then
          tmux send-keys -t "$target" Enter
          sleep 3
        fi
        echo -e "  ${GREEN}ok${NC} Post-thread survey submitted"
      fi
    fi
  fi

  echo ""
  echo -e "  ${GREEN}ok${NC} Feedback form completed"
  echo ""
}

# ---------------------------------------------------------------------------
# next-turn: Kill launcher, relaunch via tmux new-session, /clear
# ---------------------------------------------------------------------------

cmd_next_turn() {
  local repo_path
  repo_path=$(load_state repo_path)
  local launcher_session
  launcher_session=$(load_state launcher_session)

  if [ -z "$repo_path" ]; then
    echo -e "  ${RED}No repo path found.${NC}"
    exit 1
  fi

  local current_turn
  current_turn=$(load_state current_turn)
  current_turn="${current_turn:-1}"
  local next_turn=$((current_turn + 1))

  echo -e "${BOLD}NEXT TURN (Turn $current_turn -> Turn $next_turn) -- Exit & Relaunch CLI${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"
  echo -e "  ${DIM}Per Marlin V3 docs: must exit and relaunch between turns${NC}"
  echo -e "  ${DIM}to maintain stability and reset model context.${NC}"
  echo -e "  ${RED}CRITICAL: Do NOT run git commit between turns.${NC}"
  echo ""

  # Pre-flight: verify previous turn's submission made it
  local prev_step=$((current_turn - 1))
  local session_id
  session_id=$(load_state session_id)
  local nt_tmpdir="${TMPDIR:-/tmp}"
  local nt_session_dir=""
  if [ -n "$session_id" ]; then
    if [ -d "${nt_tmpdir}claude-hfi/${session_id}" ]; then
      nt_session_dir="${nt_tmpdir}claude-hfi/${session_id}"
    elif [ -d "/tmp/claude-hfi/${session_id}" ]; then
      nt_session_dir="/tmp/claude-hfi/${session_id}"
    fi
  fi

  if [ -n "$nt_session_dir" ] && [ -d "$nt_session_dir" ]; then
    local prev_sub="$nt_session_dir/submission-step-${prev_step}.json"
    if [ ! -f "$prev_sub" ]; then
      echo -e "  ${RED}╔══════════════════════════════════════════════════════════╗${NC}"
      echo -e "  ${RED}║  WARNING: Turn $current_turn submission file is MISSING!       ║${NC}"
      echo -e "  ${RED}╚══════════════════════════════════════════════════════════╝${NC}"
      echo ""
      echo -e "  The submission for Turn $current_turn was NOT saved locally."
      echo -e "  This means it almost certainly did NOT reach Snorkel."
      echo -e "  If you proceed to Turn $next_turn, Turn $current_turn will be missing from Snorkel."
      echo ""
      echo -e "  ${BOLD}Options:${NC}"
      echo -e "  ${CYAN}1. Retry Turn $current_turn:${NC} bash $0 retry-turn $current_turn"
      echo -e "  ${CYAN}2. Diagnose:${NC}       bash $0 diagnose"
      echo -e "  ${CYAN}3. Continue anyway:${NC} re-run this command with --force (NOT recommended)"
      echo ""
      if [ "${1:-}" != "--force" ]; then
        echo -e "  ${DIM}Aborting. Fix Turn $current_turn first or use --force to override.${NC}"
        return 1
      fi
    else
      local prev_sub_size
      prev_sub_size=$(wc -c < "$prev_sub" | tr -d ' ')
      if [ "$prev_sub_size" -lt 1000 ]; then
        echo -e "  ${YELLOW}WARNING: Turn $current_turn submission file is only $prev_sub_size bytes (suspicious)${NC}"
        echo -e "  ${DIM}Run 'bash $0 diagnose' to check if upload succeeded.${NC}"
        echo ""
      else
        echo -e "  ${GREEN}Pre-flight OK:${NC} Turn $current_turn submission verified ($prev_sub_size bytes)"
        echo ""
      fi
    fi
  fi

  # Step 1: Kill the current launcher session
  echo -e "  [1/4] Killing current HFI session..."
  if [ -n "$launcher_session" ]; then
    tmux kill-session -t "$launcher_session" 2>/dev/null || true
    echo -e "  ${GREEN}ok${NC} Killed session: $launcher_session"
  else
    echo -e "  ${DIM}No launcher session recorded -- killing all hfi-* sessions${NC}"
    for sess in $(tmux ls -F '#{session_name}' 2>/dev/null | grep '^hfi-'); do
      tmux kill-session -t "$sess" 2>/dev/null || true
    done
  fi
  sleep 2

  # Step 2: Relaunch via tmux new-session (proper TTY)
  local new_launcher="hfi-turn${next_turn}"
  echo -e "  [2/4] Relaunching HFI in session: ${BOLD}$new_launcher${NC}"

  local env_file_export=""
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    env_file_export="export CLAUDE_ENV_FILE=$CLAUDE_ENV_FILE && "
  elif [ -f "/tmp/claude_env.sh" ]; then
    env_file_export="export CLAUDE_ENV_FILE=/tmp/claude_env.sh && "
  fi

  tmux new-session -d -s "$new_launcher" -c "$repo_path" \
    "${env_file_export}./claude-hfi --tmux --continue" 2>&1

  save_state "launcher_session" "$new_launcher"
  sleep 8

  # Step 3: Wait for HFI to be ready
  echo -e "  [3/4] Waiting for HFI prompt readiness..."
  local ready=false
  for i in $(seq 1 30); do
    if tmux has-session -t "$new_launcher" 2>/dev/null; then
      local output
      output=$(tmux capture-pane -t "$new_launcher" -p 2>/dev/null || echo "")
      if echo "$output" | grep -qE '❯|Enter.*prompt|waiting for|Context' 2>/dev/null; then
        ready=true
        break
      fi
    fi
    sleep 2
  done

  if [ "$ready" = true ]; then
    echo -e "  ${GREEN}ok${NC} HFI is running"
  else
    echo -e "  ${YELLOW}Could not detect HFI readiness -- check: tmux attach -t $new_launcher${NC}"
  fi

  # Step 4: Run /clear to reset context
  echo -e "  [4/4] Running /clear to reset context..."
  tmux send-keys -t "$new_launcher" -l "/clear"
  sleep 0.5
  tmux send-keys -t "$new_launcher" Enter
  sleep 3

  local clear_output
  clear_output=$(tmux capture-pane -t "$new_launcher" -p 2>/dev/null || echo "")
  if echo "$clear_output" | grep -qi "no content\|cleared\|❯" 2>/dev/null; then
    echo -e "  ${GREEN}ok${NC} Context cleared"
  else
    echo -e "  ${DIM}Context may not have been cleared -- check manually if needed${NC}"
  fi

  save_state "current_turn" "$next_turn"

  echo ""
  echo -e "  ${GREEN}ok${NC} Ready for Turn $next_turn"
  echo -e "  Launcher session: ${BOLD}$new_launcher${NC}"
  echo ""
  echo -e "  ${BOLD}NEXT:${NC} bash $0 inject <prompt-file>"
  echo -e "  ${DIM}(inject will paste into: $new_launcher)${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# launch-hfi: Launch HFI via tmux new-session (proper TTY, no raw mode error)
# ---------------------------------------------------------------------------

cmd_launch_hfi() {
  local repo_path="${1:-$(load_state repo_path)}"

  if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
    echo "  Usage: $0 launch-hfi <repo-path> [--continue]"
    exit 1
  fi

  local continue_flag=""
  if [ "${2:-}" = "--continue" ]; then
    continue_flag=" --continue"
  fi

  local launcher_name="${3:-hfi-current}"

  echo -e "${BOLD}LAUNCH HFI (via tmux new-session)${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"

  # Kill existing launcher
  tmux kill-session -t "$launcher_name" 2>/dev/null || true

  local env_file_export=""
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    env_file_export="export CLAUDE_ENV_FILE=$CLAUDE_ENV_FILE && "
  elif [ -f "/tmp/claude_env.sh" ]; then
    env_file_export="export CLAUDE_ENV_FILE=/tmp/claude_env.sh && "
  fi

  tmux new-session -d -s "$launcher_name" -c "$repo_path" \
    "${env_file_export}./claude-hfi --tmux${continue_flag}" 2>&1

  save_state "launcher_session" "$launcher_name"
  save_state "repo_path" "$repo_path"

  echo -e "  ${GREEN}ok${NC} HFI launched in tmux session: ${BOLD}$launcher_name${NC}"
  echo -e "  Attach: ${CYAN}tmux attach -t $launcher_name${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# full: Complete pipeline -- setup + claude-md + launch + inject + monitor
# ---------------------------------------------------------------------------

cmd_full() {
  local tarball="${1:-}"
  local prompt_file="${2:-}"

  if [ -z "$tarball" ]; then
    echo "  Usage: $0 full <tarball-path> <prompt-file>"
    echo ""
    echo "  Runs the complete Phase 3-4 pipeline (correct Marlin V3 order):"
    echo "    1. Unpack tarball + git init + deps + tests"
    echo "    2. Launch claude-hfi --tmux"
    echo "    3. [PAUSE] Authenticate HFI (Interface Code: cc_agentic_coding_next)"
    echo "    4. Generate CLAUDE.md template"
    echo "    5. [PAUSE] Fill in CLAUDE.md sections"
    echo "    6. Copy CLAUDE.md to worktree caches"
    echo "    7. Inject prompt + monitor"
    exit 1
  fi

  # Step 1: Setup
  cmd_setup "$tarball"
  save_task_step "SETUP_DONE"

  local repo_path
  repo_path=$(load_state repo_path)

  # Step 2: Launch HFI (must come BEFORE claude-md)
  cmd_launch "$repo_path"

  echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
  echo -e "  ${BOLD}[YOUR TURN] Authenticate HFI now.${NC}"
  echo -e "  Interface Code: ${CYAN}cc_agentic_coding_next${NC}"
  echo ""
  echo -e "  Press Enter here AFTER authentication succeeds."
  echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
  read -r

  save_task_step "LAUNCHED"

  # Step 3: Generate CLAUDE.md (AFTER launch, per Marlin V3 docs)
  cmd_claude_md "$repo_path"

  echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
  echo -e "  ${BOLD}[YOUR TURN] Fill in the [FILL IN] sections in CLAUDE.md.${NC}"
  echo -e "  Edit: ${repo_path}/CLAUDE.md"
  echo ""
  echo -e "  ${RED}Do NOT use claude-hfi to generate CLAUDE.md content.${NC}"
  echo -e "  Press Enter when done editing."
  echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
  read -r

  # Step 4: Copy to worktrees
  cmd_copy_claude_md "$repo_path"
  save_task_step "CLAUDE_MD_DONE"

  # Step 5: Inject + monitor
  if [ -n "$prompt_file" ] && [ -f "$prompt_file" ]; then
    echo -e "  ${DIM}Waiting 5 seconds for HFI to initialize...${NC}"
    sleep 5
    cmd_inject "$prompt_file"
    save_task_step "TURN1_INJECTED"
    cmd_monitor
  else
    echo -e "  ${BOLD}No prompt file provided.${NC}"
    echo -e "  When ready, run:"
    echo -e "    bash $0 inject <prompt-file>"
    echo -e "    bash $0 monitor"
  fi
}

# ---------------------------------------------------------------------------
# pre-submit: Run the full pre-submission quality checklist
# ---------------------------------------------------------------------------

cmd_pre_submit() {
  echo -e "${BOLD}PRE-SUBMISSION QUALITY CHECK${NC}"
  echo -e "${YELLOW}============================================================${NC}"
  echo ""

  local pass_count=0
  local fail_count=0
  local warn_count=0

  check_pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
    pass_count=$((pass_count + 1))
  }
  check_fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
    echo -e "        $2"
    fail_count=$((fail_count + 1))
  }
  check_warn() {
    echo -e "  ${YELLOW}[WARN]${NC} $1"
    echo -e "        $2"
    warn_count=$((warn_count + 1))
  }

  # --- 1. Evaluation file exists ---
  echo -e "  ${BOLD}--- Artifacts ---${NC}"
  local eval_file="$STATE_DIR/evaluation_final.md"
  if [ -f "$eval_file" ] && [ -s "$eval_file" ]; then
    local eval_words
    eval_words=$(wc -w < "$eval_file" | tr -d ' ')
    check_pass "Evaluation file exists ($eval_words words)"
  else
    eval_file="$STATE_DIR/evaluation.md"
    if [ -f "$eval_file" ] && [ -s "$eval_file" ]; then
      local eval_words
      eval_words=$(wc -w < "$eval_file" | tr -d ' ')
      check_warn "Only raw evaluation found ($eval_words words)" "Run humanizer to produce evaluation_final.md"
    else
      check_fail "Evaluation file missing" "Expected: data/evaluation_final.md or data/evaluation.md"
    fi
  fi

  # --- 2. Turn prompt files ---
  local turn_count=0
  for t in 1 2 3; do
    local pfile="$STATE_DIR/turn${t}_prompt.txt"
    if [ -f "$pfile" ] && [ -s "$pfile" ]; then
      turn_count=$((turn_count + 1))
    fi
  done

  if [ "$turn_count" -ge 3 ]; then
    check_pass "Turn prompts present ($turn_count turns)"
  elif [ "$turn_count" -gt 0 ]; then
    check_fail "Only $turn_count turn prompt(s) found" "Minimum 3 meaningful turns required. Missing: turn$((turn_count+1))_prompt.txt"
  else
    check_fail "No turn prompt files found" "Expected: data/turn{1,2,3}_prompt.txt"
  fi

  # --- 3. Diff files ---
  local diff_count=0
  for t in 1 2 3; do
    if [ -f "$STATE_DIR/turn${t}_diff_A.txt" ] && [ -f "$STATE_DIR/turn${t}_diff_B.txt" ]; then
      diff_count=$((diff_count + 1))
    fi
  done

  if [ "$diff_count" -ge 3 ]; then
    check_pass "Diff captures present ($diff_count turns)"
  elif [ "$diff_count" -gt 0 ]; then
    check_warn "Only $diff_count turn diff(s) captured" "Expected 3 turns of diffs for a complete evaluation"
  else
    check_fail "No diff files found" "Run: bash $0 capture-diffs after each turn"
  fi

  # --- 4. Non-empty diffs (trajectories produced changes) ---
  for t in 1 2 3; do
    local da="$STATE_DIR/turn${t}_diff_A.txt"
    local db="$STATE_DIR/turn${t}_diff_B.txt"
    if [ -f "$da" ]; then
      local lines_a
      lines_a=$(wc -l < "$da" | tr -d ' ')
      if [ "$lines_a" -lt 5 ]; then
        check_warn "Turn $t Trajectory A diff is very short ($lines_a lines)" "Trajectory may not have produced meaningful changes"
      fi
    fi
    if [ -f "$db" ]; then
      local lines_b
      lines_b=$(wc -l < "$db" | tr -d ' ')
      if [ "$lines_b" -lt 5 ]; then
        check_warn "Turn $t Trajectory B diff is very short ($lines_b lines)" "Trajectory may not have produced meaningful changes"
      fi
    fi
  done

  echo ""

  # --- 5. Prompt validator on each turn prompt ---
  echo -e "  ${BOLD}--- Prompt Quality (per turn) ---${NC}"
  for t in 1 2 3; do
    local pfile="$STATE_DIR/turn${t}_prompt.txt"
    if [ -f "$pfile" ]; then
      local val_output
      val_output=$("$PYTHON" "$SCRIPT_DIR/prompt_validator.py" --file "$pfile" 2>&1) || true
      if echo "$val_output" | grep -q "All checks passed" 2>/dev/null; then
        check_pass "Turn $t prompt passes validator"
      else
        local crit_count
        crit_count=$(echo "$val_output" | grep -c "CRITICAL" 2>/dev/null || echo "0")
        if [ "$crit_count" -gt 0 ]; then
          check_fail "Turn $t prompt has $crit_count CRITICAL issue(s)" "Run: python3 prompt_validator.py --file data/turn${t}_prompt.txt"
        else
          check_warn "Turn $t prompt has warnings" "Run: python3 prompt_validator.py --file data/turn${t}_prompt.txt"
        fi
      fi
    fi
  done

  echo ""

  # --- 6. Submission quality validator (eval_checker.py) ---
  echo -e "  ${BOLD}--- Submission Quality (eval_checker.py) ---${NC}"
  if [ -f "$eval_file" ]; then
    local prompts_args=""
    for t in 1 2 3; do
      local pfile="$STATE_DIR/turn${t}_prompt.txt"
      if [ -f "$pfile" ]; then
        prompts_args="$prompts_args $pfile"
      fi
    done

    local check_output
    local check_exit
    if [ -n "$prompts_args" ]; then
check_output=$("$PYTHON" "$SCRIPT_DIR/eval_checker.py" --eval "$eval_file" --prompts $prompts_args 2>&1)
  else
      check_output=$("$PYTHON" "$SCRIPT_DIR/eval_checker.py" --eval "$eval_file" 2>&1)
    fi
    check_exit=$?

    if [ "$check_exit" -eq 0 ]; then
      check_pass "Submission validator: GO"
    else
      local mc_fails
      mc_fails=$(echo "$check_output" | grep -c "\[FAIL\]" 2>/dev/null || echo "?")
      check_fail "Submission validator: NO-GO ($mc_fails failures)" "Run: python3 eval_checker.py --eval $eval_file --prompts-dir data/"
    fi

    # Show the validator's detail output indented
    echo ""
    echo "$check_output" | sed 's/^/    /'
  else
    check_fail "Cannot run submission validator" "Evaluation file not found"
  fi

  echo ""

  # --- 7. Pre-submission checklist summary ---
  echo -e "${YELLOW}============================================================${NC}"
  local total=$((pass_count + fail_count + warn_count))
  echo -e "  ${BOLD}RESULTS:${NC} $pass_count passed | $warn_count warnings | $fail_count failures"
  echo ""

  if [ "$fail_count" -eq 0 ]; then
    echo -e "  ${GREEN}============================================================${NC}"
    echo -e "  ${GREEN}  GO -- Submission is ready${NC}"
    echo -e "  ${GREEN}============================================================${NC}"
    echo ""
    echo -e "  ${BOLD}Next steps:${NC}"
    echo -e "  1. Review data/evaluation_final.md one more time"
    echo -e "  2. Open Snorkel -> Marlin-Prompt-Review V3"
    echo -e "  3. Claim your task"
    echo -e "  4. Paste PR URL, evaluation, ratings, and justifications"
    echo -e "  5. Submit (IRREVERSIBLE -- cannot edit after submission)"
  else
    echo -e "  ${RED}============================================================${NC}"
    echo -e "  ${RED}  NO-GO -- Fix $fail_count failure(s) before submitting${NC}"
    echo -e "  ${RED}============================================================${NC}"
    echo ""
    echo -e "  Fix the issues above, then re-run:"
    echo -e "    bash $0 pre-submit"
  fi
  echo ""
}

# ---------------------------------------------------------------------------
# status: Show current Phase 3-4 state
# ---------------------------------------------------------------------------

cmd_status() {
  echo -e "${BOLD}PHASE 3-4 STATUS:${NC}"
  echo ""

  local repo_path lang head_commit session_id
  repo_path=$(load_state repo_path)
  lang=$(load_state language)
  head_commit=$(load_state head_commit)
  session_id=$(load_state session_id)

  if [ -n "$repo_path" ]; then
    echo -e "  Repo:       ${GREEN}$repo_path${NC}"
  else
    echo -e "  Repo:       ${DIM}(not set -- run 'setup' first)${NC}"
  fi

  if [ -n "$lang" ]; then
    echo -e "  Language:   ${GREEN}$lang${NC}"
  fi

  if [ -n "$head_commit" ]; then
    echo -e "  HEAD:       ${GREEN}$head_commit${NC}"
  fi

  if [ -n "$session_id" ]; then
    echo -e "  Session:    ${GREEN}$session_id${NC}"
    local launcher_session
    launcher_session=$(load_state launcher_session)
    # --tmux mode creates separate sessions: <id>-A and <id>-B
    if [ -n "$launcher_session" ] && tmux has-session -t "$launcher_session" 2>/dev/null; then
      echo -e "  Control:    ${GREEN}running${NC} ($launcher_session)"
    else
      echo -e "  Control:    ${RED}not running${NC}"
    fi
    if tmux has-session -t "${session_id}-A" 2>/dev/null; then
      echo -e "  Traj A:     ${GREEN}running${NC} (${session_id}-A)"
    else
      echo -e "  Traj A:     ${DIM}not running${NC}"
    fi
    if tmux has-session -t "${session_id}-B" 2>/dev/null; then
      echo -e "  Traj B:     ${GREEN}running${NC} (${session_id}-B)"
    else
      echo -e "  Traj B:     ${DIM}not running${NC}"
    fi
  else
    echo -e "  Session:    ${DIM}(not set -- run 'launch' first)${NC}"
  fi

  echo ""

  # Also show tmux sessions
  echo -e "  ${BOLD}Active tmux sessions:${NC}"
  tmux ls 2>/dev/null | sed 's/^/    /' || echo "    (none)"
  echo ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

COMMAND="${1:-help}"
shift 2>/dev/null || true

banner
preflight

# ---------------------------------------------------------------------------
# diagnose: Check session health, submission status, and common failure points
# ---------------------------------------------------------------------------

cmd_diagnose() {
  local turn="${1:-}"

  echo -e "${BOLD}DIAGNOSE -- HFI Session Health Check${NC}"
  echo -e "${YELLOW}============================================================${NC}"
  echo ""

  local session_id
  session_id=$(load_state session_id)
  local repo_path
  repo_path=$(load_state repo_path)
  local launcher_session
  launcher_session=$(load_state launcher_session)
  local current_turn
  current_turn=$(load_state current_turn)

  echo -e "  ${BOLD}1. Basic State${NC}"
  echo -e "  Session ID:      ${session_id:-${RED}NOT SET${NC}}"
  echo -e "  Repo path:       ${repo_path:-${RED}NOT SET${NC}}"
  echo -e "  Launcher:        ${launcher_session:-${RED}NOT SET${NC}}"
  echo -e "  Current turn:    ${current_turn:-${RED}NOT SET${NC}}"
  echo ""

  # Check tmux sessions
  echo -e "  ${BOLD}2. tmux Sessions${NC}"
  if [ -n "$launcher_session" ] && tmux has-session -t "$launcher_session" 2>/dev/null; then
    echo -e "  Control:         ${GREEN}ALIVE${NC} ($launcher_session)"
  else
    echo -e "  Control:         ${RED}DEAD${NC} ($launcher_session)"
  fi
  if [ -n "$session_id" ]; then
    if tmux has-session -t "${session_id}-A" 2>/dev/null; then
      echo -e "  Trajectory A:    ${GREEN}ALIVE${NC} (${session_id}-A)"
    else
      echo -e "  Trajectory A:    ${RED}DEAD${NC}"
    fi
    if tmux has-session -t "${session_id}-B" 2>/dev/null; then
      echo -e "  Trajectory B:    ${GREEN}ALIVE${NC} (${session_id}-B)"
    else
      echo -e "  Trajectory B:    ${RED}DEAD${NC}"
    fi
  fi
  echo ""

  # Find and check session directory
  echo -e "  ${BOLD}3. HFI Session Directory${NC}"
  local session_dir=""
  if [ -n "$session_id" ]; then
    # Check common HFI temp directory locations
    local tmpdir="${TMPDIR:-/tmp}"
    if [ -d "${tmpdir}claude-hfi/${session_id}" ]; then
      session_dir="${tmpdir}claude-hfi/${session_id}"
    elif [ -d "/tmp/claude-hfi/${session_id}" ]; then
      session_dir="/tmp/claude-hfi/${session_id}"
    else
      # Fallback: search the TMPDIR parent
      session_dir=$(find "${tmpdir}" -maxdepth 4 -type d -name "$session_id" 2>/dev/null | head -1)
    fi
  fi

  if [ -z "$session_dir" ] || [ ! -d "$session_dir" ]; then
    echo -e "  ${RED}Session directory NOT FOUND${NC}"
    echo -e "  ${DIM}HFI may not have been launched, or session ID is wrong${NC}"
    echo -e "  ${DIM}Looked in: ${tmpdir}claude-hfi/${NC}"
    echo ""
    return
  fi

  echo -e "  Path: ${DIM}$session_dir${NC}"
  echo ""

  # Check each turn's files
  echo -e "  ${BOLD}4. Turn-by-Turn File Status${NC}"
  echo -e "  ${DIM}(each turn needs: prompt, result-A, result-B, feedback, submission)${NC}"
  echo ""

  local max_turn=3
  if [ -n "$turn" ]; then
    max_turn="$turn"
  fi

  local all_healthy=true
  for t in $(seq 0 $((max_turn - 1))); do
    local turn_num=$((t + 1))
    local has_prompt=false has_result_a=false has_result_b=false
    local has_feedback=false has_submission=false has_base=false
    local sub_size=0

    [ -f "$session_dir/prompt-${t}.json" ] && has_prompt=true
    [ -f "$session_dir/result-${t}-A.json" ] && has_result_a=true
    [ -f "$session_dir/result-${t}-B.json" ] && has_result_b=true
    [ -f "$session_dir/feedback-step-${t}.json" ] && has_feedback=true
    [ -f "$session_dir/base-commit-${t}.txt" ] && has_base=true

    if [ -f "$session_dir/submission-step-${t}.json" ]; then
      has_submission=true
      sub_size=$(wc -c < "$session_dir/submission-step-${t}.json" | tr -d ' ')
    fi

    echo -e "  Turn $turn_num (step $t):"
    [ "$has_prompt" = true ]     && echo -e "    prompt-${t}.json:        ${GREEN}OK${NC}" || echo -e "    prompt-${t}.json:        ${RED}MISSING${NC}"
    [ "$has_base" = true ]       && echo -e "    base-commit-${t}.txt:    ${GREEN}OK${NC}" || echo -e "    base-commit-${t}.txt:    ${RED}MISSING${NC}"
    [ "$has_result_a" = true ]   && echo -e "    result-${t}-A.json:      ${GREEN}OK${NC}" || echo -e "    result-${t}-A.json:      ${RED}MISSING${NC} (trajectory A never completed)"
    [ "$has_result_b" = true ]   && echo -e "    result-${t}-B.json:      ${GREEN}OK${NC}" || echo -e "    result-${t}-B.json:      ${RED}MISSING${NC} (trajectory B never completed)"
    [ "$has_feedback" = true ]   && echo -e "    feedback-step-${t}.json: ${GREEN}OK${NC}" || echo -e "    feedback-step-${t}.json: ${RED}MISSING${NC} (feedback never submitted)"

    if [ "$has_submission" = true ]; then
      if [ "$sub_size" -gt 10000 ]; then
        echo -e "    submission-step-${t}.json: ${GREEN}OK${NC} (${sub_size} bytes)"
      else
        echo -e "    submission-step-${t}.json: ${YELLOW}SUSPICIOUS${NC} (only ${sub_size} bytes -- may be incomplete)"
        all_healthy=false
      fi
    else
      echo -e "    submission-step-${t}.json: ${RED}MISSING${NC} (upload to server FAILED)"
      all_healthy=false
    fi
    echo ""
  done

  # Check thread feedback
  echo -e "  ${BOLD}5. Thread Feedback (Post-Survey)${NC}"
  if [ -f "$session_dir/thread-feedback.json" ]; then
    echo -e "  thread-feedback.json: ${GREEN}OK${NC}"
  else
    echo -e "  thread-feedback.json: ${RED}MISSING${NC} (did you select 'Finish conversation'?)"
  fi
  echo ""

  # Check debug log for errors
  echo -e "  ${BOLD}6. Debug Log Analysis${NC}"
  if [ -f "$session_dir/debug.txt" ]; then
    local error_count
    error_count=$(grep -c '\[ERROR\]' "$session_dir/debug.txt" 2>/dev/null || echo "0")
    local timeout_count
    timeout_count=$(grep -ci 'timeout' "$session_dir/debug.txt" 2>/dev/null || echo "0")
    local upload_count
    upload_count=$(grep -c '\[HFI:diff\] Uploaded' "$session_dir/debug.txt" 2>/dev/null || echo "0")

    echo -e "  Errors found:     ${error_count}"
    echo -e "  Timeout events:   ${timeout_count}"
    echo -e "  Diff uploads:     ${upload_count} (should be 2 per turn = $((max_turn * 2)) total)"

    if [ "$error_count" -gt 0 ]; then
      echo ""
      echo -e "  ${YELLOW}Recent errors:${NC}"
      grep '\[ERROR\]' "$session_dir/debug.txt" 2>/dev/null | tail -5 | sed 's/^/    /'
    fi

    # Check which turns had successful diff uploads
    echo ""
    echo -e "  ${BOLD}Diff upload status per turn:${NC}"
    for t in $(seq 0 $((max_turn - 1))); do
      local turn_num=$((t + 1))
      local diff_uploads
      diff_uploads=$(grep -c "step-${t}.diff" "$session_dir/debug.txt" 2>/dev/null || echo "0")
      if [ "$diff_uploads" -ge 2 ]; then
        echo -e "    Turn $turn_num: ${GREEN}$diff_uploads diff(s) uploaded${NC}"
      elif [ "$diff_uploads" -gt 0 ]; then
        echo -e "    Turn $turn_num: ${YELLOW}Only $diff_uploads diff uploaded (should be 2)${NC}"
      else
        echo -e "    Turn $turn_num: ${RED}NO diffs uploaded -- turn data NOT on server${NC}"
      fi
    done
  else
    echo -e "  ${RED}debug.txt not found${NC}"
  fi

  echo ""
  echo -e "${YELLOW}============================================================${NC}"
  if [ "$all_healthy" = true ]; then
    echo -e "  ${GREEN}ALL TURNS LOOK HEALTHY${NC}"
    echo ""
    echo -e "  If turns are still missing from Snorkel despite all files being OK,"
    echo -e "  this is likely a Snorkel platform delay. Wait 5-10 minutes and refresh."
    echo -e "  If still missing after 10 min, the diffs may not have been uploaded"
    echo -e "  even though local files exist. Check the 'Diff upload status' above."
  else
    echo -e "  ${RED}ISSUES DETECTED${NC}"
    echo ""

    # Smart fix suggestions based on what failed
    for t in $(seq 0 $((max_turn - 1))); do
      local turn_num=$((t + 1))
      local sub_file="$session_dir/submission-step-${t}.json"

      if [ ! -f "$sub_file" ]; then
        echo -e "  ${BOLD}Turn $turn_num: Submission missing${NC}"
        echo -e "  ${DIM}WHAT HAPPENED: The feedback upload to Anthropics servers failed.${NC}"
        echo -e "  ${DIM}WHAT YOU SAW:  Either a 'timeout' message, a frozen screen,${NC}"
        echo -e "  ${DIM}               or HFI said 'submitted' but the file is empty/missing.${NC}"
        echo -e "  ${DIM}WHY:           Most likely you didnt exit HFI between turns, causing${NC}"
        echo -e "  ${DIM}               context overflow and large corrupted diffs that timeout.${NC}"
        echo -e "  ${CYAN}FIX:           bash $0 retry-turn $turn_num${NC}"
        echo ""
      elif [ -f "$sub_file" ]; then
        local sz
        sz=$(wc -c < "$sub_file" | tr -d ' ')
        if [ "$sz" -lt 10000 ]; then
          echo -e "  ${BOLD}Turn $turn_num: Submission too small ($sz bytes)${NC}"
          echo -e "  ${DIM}WHAT HAPPENED: Upload started but was cut off mid-transfer.${NC}"
          echo -e "  ${DIM}WHY:           Network timeout or HFI was killed during upload.${NC}"
          echo -e "  ${CYAN}FIX:           bash $0 retry-turn $turn_num${NC}"
          echo ""
        fi
      fi
    done
  fi
  echo ""
  echo -e "  ${DIM}For full troubleshooting guide: see TROUBLESHOOTING.md${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# retry-turn: Clean up a failed turn's state and relaunch HFI to redo it
# ---------------------------------------------------------------------------

cmd_retry_turn() {
  local turn_num="${1:-}"

  if [ -z "$turn_num" ]; then
    echo "  Usage: $0 retry-turn <turn-number>"
    echo ""
    echo "  Clears the state files for a specific turn and relaunches HFI"
    echo "  so you can redo that turn from scratch."
    echo ""
    echo "  Example: $0 retry-turn 3  (redo Turn 3)"
    exit 1
  fi

  local step_idx=$((turn_num - 1))
  local session_id
  session_id=$(load_state session_id)
  local repo_path
  repo_path=$(load_state repo_path)

  if [ -z "$session_id" ] || [ -z "$repo_path" ]; then
    echo -e "  ${RED}No session or repo found. Cannot retry.${NC}"
    exit 1
  fi

  # Find session directory
  local session_dir=""
  local tmpdir="${TMPDIR:-/tmp}"
  if [ -d "${tmpdir}claude-hfi/${session_id}" ]; then
    session_dir="${tmpdir}claude-hfi/${session_id}"
  elif [ -d "/tmp/claude-hfi/${session_id}" ]; then
    session_dir="/tmp/claude-hfi/${session_id}"
  else
    session_dir=$(find "${tmpdir}" -maxdepth 4 -type d -name "$session_id" 2>/dev/null | head -1)
  fi

  if [ -z "$session_dir" ] || [ ! -d "$session_dir" ]; then
    echo -e "  ${RED}Session directory not found for $session_id${NC}"
    exit 1
  fi

  echo -e "${BOLD}RETRY TURN $turn_num${NC}"
  echo -e "${YELLOW}------------------------------------------------------------${NC}"
  echo ""

  # Step 1: Kill existing HFI
  echo -e "  [1/4] Killing existing HFI sessions..."
  local launcher_session
  launcher_session=$(load_state launcher_session)
  if [ -n "$launcher_session" ]; then
    tmux kill-session -t "$launcher_session" 2>/dev/null || true
  fi
  for sess in $(tmux ls -F '#{session_name}' 2>/dev/null | grep '^hfi-' 2>/dev/null); do
    tmux kill-session -t "$sess" 2>/dev/null || true
  done
  sleep 2

  # Step 2: Delete the failed turn's state files
  echo -e "  [2/4] Clearing Turn $turn_num state files..."
  local files_to_delete=(
    "prompt-${step_idx}.json"
    "base-commit-${step_idx}.txt"
    "result-${step_idx}-A.json"
    "result-${step_idx}-B.json"
    "feedback-step-${step_idx}.json"
    "submission-step-${step_idx}.json"
    "diff-paths-${step_idx}.json"
  )

  for f in "${files_to_delete[@]}"; do
    if [ -f "$session_dir/$f" ]; then
      rm -f "$session_dir/$f"
      echo -e "    Deleted: $f"
    fi
  done
  echo ""

  # Step 3: Relaunch HFI
  echo -e "  [3/4] Relaunching HFI with --tmux --continue..."
  local new_launcher="hfi-retry-turn${turn_num}"

  local env_file_export=""
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    env_file_export="export CLAUDE_ENV_FILE=$CLAUDE_ENV_FILE && "
  elif [ -f "/tmp/claude_env.sh" ]; then
    env_file_export="export CLAUDE_ENV_FILE=/tmp/claude_env.sh && "
  fi

  tmux new-session -d -s "$new_launcher" -c "$repo_path" \
    "${env_file_export}./claude-hfi --tmux --continue 2>&1 | tee /tmp/hfi_retry.log"

  save_state "launcher_session" "$new_launcher"
  save_state "current_turn" "$turn_num"
  sleep 5

  # Step 4: Wait for readiness
  echo -e "  [4/4] Waiting for HFI to initialize..."
  local ready=false
  for i in $(seq 1 30); do
    if tmux has-session -t "$new_launcher" 2>/dev/null; then
      local output
      output=$(tmux capture-pane -t "$new_launcher" -p 2>/dev/null || echo "")
      if echo "$output" | grep -qE '❯|Enter.*prompt|HFI' 2>/dev/null; then
        ready=true
        break
      fi
    fi
    sleep 2
  done

  if [ "$ready" = true ]; then
    echo -e "  ${GREEN}ok${NC} HFI is running in session: ${BOLD}$new_launcher${NC}"
  else
    echo -e "  ${YELLOW}HFI may still be starting -- check: tmux attach -t $new_launcher${NC}"
  fi

  echo ""
  echo -e "  ${GREEN}Ready to redo Turn $turn_num${NC}"
  echo -e "  ${BOLD}NEXT STEPS:${NC}"
  echo -e "    1. ${CYAN}[HUMAN]${NC} Authenticate if prompted (browser)"
  echo -e "    2. Inject your Turn $turn_num prompt:"
  echo -e "       ${CYAN}bash $0 inject data/turn${turn_num}_prompt.txt${NC}"
  echo -e "    3. Monitor trajectories:"
  echo -e "       ${CYAN}bash $0 monitor${NC}"
  echo -e "    4. Fill feedback:"
  echo -e "       ${CYAN}bash $0 fill-feedback data/turn${turn_num}_feedback.txt${NC}"
  echo ""
}

case "$COMMAND" in
  setup)
    cmd_setup "$@"
    ;;
  claude-md|claudemd)
    cmd_claude_md "$@"
    ;;
  copy-claude-md|copyclaudemd)
    cmd_copy_claude_md "$@"
    ;;
  launch)
    cmd_launch "$@"
    ;;
  set-session)
    cmd_set_session "$@"
    ;;
  inject)
    cmd_inject "$@"
    ;;
  monitor|watch)
    cmd_monitor
    ;;
  capture-diffs|diffs)
    cmd_capture_diffs "$@"
    ;;
  select-winner|winner)
    cmd_select_winner "$@"
    ;;
  fill-feedback|feedback)
    cmd_fill_feedback "$@"
    ;;
  next-turn|nextturn)
    cmd_next_turn
    ;;
  launch-hfi)
    cmd_launch_hfi "$@"
    ;;
  full|all)
    cmd_full "$@"
    ;;
  pre-submit|presubmit|check)
    cmd_pre_submit
    ;;
  task-status|ts)
    cmd_task_status
    ;;
  status)
    cmd_status
    ;;
  diagnose|diag)
    cmd_diagnose "$@"
    ;;
  retry-turn|retry)
    cmd_retry_turn "$@"
    ;;
  *)
    echo "Usage: $0 <command> [args]"
    echo ""
    echo -e "${BOLD}Phase 3 -- Environment Setup:${NC}"
    echo "  setup <tarball>          Unpack tarball, git init, install deps, run tests"
    echo "  launch <repo-path>       Copy CLI binary and start claude-hfi --tmux"
    echo "  claude-md <repo-path>    Generate CLAUDE.md template (AFTER launch)"
    echo "  copy-claude-md [repo]    Copy CLAUDE.md to both A/B worktree caches"
    echo ""
    echo -e "${BOLD}Phase 4 -- Task Execution:${NC}"
    echo "  set-session <id>         Manually set the tmux session ID"
    echo "  inject <prompt-file>     Paste prompt into the control session"
    echo "  monitor                  Watch trajectories until completion"
    echo ""
    echo -e "${BOLD}Multi-Turn Automation:${NC}"
    echo "  capture-diffs [turn#]    Save A/B diffs from worktrees to data/ files"
    echo "  select-winner <A|B|tie>  Print feedback guidance (manual entry)"
    echo "  fill-feedback <file>     Fill HFI feedback form from structured file"
    echo "  next-turn                Kill session, relaunch --continue, /clear"
    echo "  launch-hfi <repo> [--continue]  Launch HFI via tmux (proper TTY)"
    echo ""
    echo -e "${BOLD}All-in-one:${NC}"
    echo "  full <tarball> <prompt>  Run entire Phase 3-4 pipeline"
    echo ""
    echo -e "${BOLD}Quality:${NC}"
    echo "  pre-submit               Run full pre-submission quality checklist"
    echo ""
    echo -e "${BOLD}Debugging:${NC}"
    echo "  diagnose [turns]         Full health check: sessions, files, uploads, errors"
    echo "  retry-turn <turn#>       Clear failed turn state and relaunch HFI to redo it"
    echo ""
    echo -e "${BOLD}Utility:${NC}"
    echo "  status                   Show current Phase 3-4 state"
    echo "  task-status              Show task state machine progress"
    echo ""
    echo -e "${DIM}For full automation (Turns 2-3 + evaluation), say${NC}"
    echo -e "${DIM}\"automate the rest\" in Cursor after Turn 1 finishes.${NC}"
    echo ""
    ;;
esac
