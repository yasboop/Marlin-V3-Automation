============================================================
MARLIN V3 - PROMPT PREPARATION (READY TO SUBMIT)
============================================================

PROMPT CATEGORY: Performance

PROMPT CATEGORY - OTHER:

------------------------------------------------------------
CONTEXT SETTING
------------------------------------------------------------

REPO DEFINITION:
TensorFlow is an open source ML framework, mostly C++ and Python, built around a dataflow computation graph that gets compiled and optimized before running on CPUs, GPUs or TPUs. The XLA (Accelerated Linear Algebra) compiler sits inside it and is responsible for taking HLO (High Level Optimizer) graphs and turning them into efficient machine code for each backend. One of the key subsystems in XLA is the Memory Space Assignment (MSA) module under xla/service/memory_space_assignment/ which decides at compile time whether tensors should live in default memory (HBM) or faster alternate memory (VMEM/SRAM), and handles all the prefetching and eviction scheduling around that

PR DEFINITION:
Right now when a conditional operation has an input that is sitting in alternate memory, the MSA algorithm just forces an eviction to default memory before the conditional runs. After the conditional finishes, if the same buffer is needed again it has to be prefetched back. The problem is that in many cases this eviction is actually not needed at all, the buffer could just stay in alternate memory the whole time if the uses inside the conditional branches can also read from there. The change basically makes the algorithm smarter about detecting when the conditional operand is already pinned in alternate memory for the whole duration and creates mirrored allocations for the branch parameters instead of forcing an unnecessary copy back to default memory

------------------------------------------------------------
TASK APPROACH
------------------------------------------------------------

EDGE CASES:
1. MirroredAllocation right now only works in default memory space for while loop eviction scenarios. Extending it to work in alternate memory means the constructor, Process() method and the MarkNeeded() chain all need updating, if any of those still assume default memory you get a wrong memory space tag on the allocation and the verifier blows up
2. When checking if a conditional operand can stay in alternate memory, you have to scan all uses inside every branch computation. If even one use has a required assignment in default memory (like a custom call that only accepts HBM buffers), the whole thing needs to fall back to eviction. Missing this check means the allocator puts a buffer in VMEM that a consumer cant actually read from
3. The aliased offset tracking uses CreateOrAddToAliasedOffset which asserts the allocation isnt already in the map. For mirrored allocations in alternate memory you cant add them to the offset map because they share an offset with the original allocation, so the function needs to skip mirrored allocations or you get a duplicate key crash
4. Async conversion candidates inside conditional branches need special handling because creating a mirrored allocation for them would end up as an alt to alt copy which is not supported. Those need to fall back to a pinned default memory allocation instead

ACCEPTANCE CRITERIA:
1. Conditional operands that are in alternate memory for the whole conditional duration should not require eviction, the buffer stays in VMEM and branch parameters get mirrored allocations pointing to the same chunk
2. If any use inside a branch computation has a required assignment in default memory or is not allowed in alternate memory, the algorithm should fall back to forcing eviction like it does right now
3. MirroredAllocation needs a new constructor that accepts a defining_position along with start and end times, and it should carry the memory space of the original allocation instead of always being default
4. The verification logic in MemorySpaceAssignment::VerifyAllocations should skip mirrored allocations when checking for overlapping intervals in alternate memory, since they dont reserve new space
5. Existing tests like ConditionalMultiUse and ConditionalMultiUseInWhile should pass with the updated behavior where evictions are no longer forced unnecessarily

EFFORT AND COMPLEXITY:
The allocation hierarchy has around 8 concrete subclasses of Allocation and adding a new virtual method is_mirrored_allocation() to the base class means touching every single one of them. The core algorithm change in AllocateAllocationValues is tricky because you need to track which allocation values inside conditional branches are already covered by the outer allocations pre-allocated state, and skip them during the normal allocation loop without breaking the ordering assumptions that the rest of the algorithm relies on. The eviction check itself needs to walk through all allocation values inside the conditional time range, inspect their uses for required assignments and aliased constraints, any of which could force a fallback

TESTING SETUP: Yes

------------------------------------------------------------
PROMPT DEFINITION
------------------------------------------------------------

INITIAL PROMPT:
XLA's Memory Space Assignment algorithm is being too aggressive about evicting conditional operands from alternate memory. When a buffer is sitting in VMEM and gets passed into a conditional, the algorithm forces it back to default memory before the conditional runs even if all uses inside the branches can perfectly well read from alternate memory. The eviction and subsequent prefetch are wasting bandwidth for no reason. The allocator needs to detect when a conditional operand is already pinned in alternate memory for the whole duration of the conditional and skip the eviction in those cases. Branch parameters inside the conditional computations should get mirrored allocations that point to the same alternate memory chunk instead of getting their own default memory copies. If any use inside a branch actually requires default memory or cant work with alternate memory, the eviction should still happen as a fallback. The MirroredAllocation type needs extending to support alternate memory since it was originally designed only for default memory while loop scenarios. Verification and offset tracking also need updates to handle mirrored allocations in VMEM correctly. Tests should cover both the happy path and the fallback case

============================================================
QUALITY CHECK RESULTS
============================================================
- Em-dashes found: No
- PR references found: No
- Role-based prompting: No
- Over-prescriptive: No, describes the problem and desired outcome without specifying exact file changes or implementation steps
- Word count: 178 words
- Reads like human-written issue: Yes, natural dev prose with varied structure and no parallel list patterns
