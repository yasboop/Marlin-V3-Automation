============================================================
MARLIN V3 - PROMPT PREPARATION (READY TO SUBMIT)
============================================================

PROMPT CATEGORY: Code Review

PROMPT CATEGORY - OTHER:

------------------------------------------------------------
CONTEXT SETTING
------------------------------------------------------------

REPO DEFINITION:
Elasticsearch is a distributed search and analytics engine written in Java, basically the core of the Elastic Stack. The main codebase sits under the server/ module which handles cluster state management, indexing, querying and all the distributed coordination stuff like shard allocation and metadata persistence. It uses a custom serialization framework (Writeable/StreamInput/StreamOutput) for node-to-node transport and XContent for REST and cluster state persistence. Gets used pretty widely for log analytics, full-text search and observability workloads at scale

PR DEFINITION:
The index metadata in Elasticsearch doesnt currently have any way to track an in-progress shard split operation persistently. If a split is happening and something goes wrong midway, theres no state in the cluster metadata to know where things left off. This change introduces a resharding metadata structure that gets attached to IndexMetadata so the cluster can track source and target shard states during a split. It adds new classes for the state model along with serialization support and wires everything into the existing IndexMetadata builder and parser

------------------------------------------------------------
TASK APPROACH
------------------------------------------------------------

EDGE CASES:
1. The IndexReshardingState is a sealed interface with Noop and Split as implementations, so the serialization layer needs to handle the type dispatch correctly. If a new state variant gets added later and the deserialization doesnt account for unknown ordinals, it will blow up on mixed-version clusters
2. Source shard state transitions have ordering constraints where a source cant move to DONE until all its corresponding target shards are DONE first. The builder's setSourceShardState enforces this with assertions but production code paths need to respect it too, otherwise you get an inconsistent split state that cant make progress
3. IndexMetadata already has a massive constructor with 30+ parameters and adding reshardingMetadata as nullable at the end means every existing call site that constructs IndexMetadata directly (withMappingMetadata, withInSyncAllocationIds, etc.) needs updating. Missing even one is a silent bug since Java wont catch it
4. The XContent round-trip for the Split state stores shard counts and per-shard state arrays, so if the arrays dont match the declared shard counts during parsing you end up with ArrayIndexOutOfBoundsException at runtime instead of a clean validation error

ACCEPTANCE CRITERIA:
1. Review should identify whether the sealed interface approach for IndexReshardingState gives enough extensibility for future resharding operations beyond split
2. Serialization round-trip correctness for both Noop and Split states, including the per-shard state arrays
3. The state transition constraints in Split.Builder need to be analyzed for correctness, specifically whether assertions are sufficient or if IllegalStateException would be more appropriate for production
4. Analysis of how the nullable reshardingMetadata field interacts with the existing IndexMetadata construction pattern across all the withX methods
5. Test coverage should be evaluated for whether it exercises the state transition ordering constraints, not just serialization

EFFORT AND COMPLEXITY:
The resharding state model involves a sealed interface hierarchy with two implementations where one of them (Split) carries per-shard state arrays with ordering constraints on transitions. Reviewing this properly means tracing through how IndexMetadata gets constructed and copied across 6 different withX methods to make sure the new nullable field propagates correctly everywhere. The serialization has to work across both Writeable (transport) and XContent (persistence) paths and the state transition logic in the builder uses assertions that behave differently depending on JVM flags, so you have to reason about what happens in production when assertions are disabled

TESTING SETUP: Yes

------------------------------------------------------------
PROMPT DEFINITION
------------------------------------------------------------

INITIAL PROMPT:
Elasticsearch's IndexMetadata is getting a new resharding metadata structure to track in-progress shard split operations. The implementation introduces a sealed interface for resharding states with Noop and Split variants, where Split carries per-shard source and target state arrays with ordering constraints on transitions. Review the design and implementation focusing on the state model's extensibility, whether the serialization handles edge cases around the type dispatch and array bounds properly, and how the nullable metadata field integrates with IndexMetadata's existing construction and copy patterns. Flag any concerns about the assertion-based validation approach in production code paths and evaluate if the test coverage exercises the important state transition constraints

============================================================
QUALITY CHECK RESULTS
============================================================
- Em-dashes found: No
- PR references found: No
- Role-based prompting: No
- Over-prescriptive: No, describes areas to review without prescribing specific findings
- Word count: 103 words
- Reads like human-written issue: Yes, natural dev prose with varied structure
