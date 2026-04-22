# Implementation Plan: xpath-dir

## Overview

Implement xpath-dir as a single executable bash script that queries file directory structures using XPath-like syntax. The implementation follows the component architecture from the design: Query Parser, File System Adapter, Query Evaluator, Predicate Engine, Operator Engine, Built-in Functions, and Result Formatter. Each component is implemented as a set of bash functions within the single script file, wired together at the end. Testing uses `bats` framework.

## Tasks

- [ ] 1. Create script skeleton and core data structures
  - [ ] 1.1 Create the `xpath-dir` executable bash script with shebang, argument validation, and main entry point
    - Check for bash 4.0+ (associative array support)
    - Validate that exactly one argument (query string) is provided
    - Print usage to stderr and exit 1 if no argument given
    - Define global associative arrays for AST (STEPS, STEP_AXES, PREDICATES, QUERY_TYPE, UNION_QUERIES)
    - Define global associative arrays for node cache (NODE_TYPE, NODE_NAME, ATTR_PERMISSIONS, ATTR_ITEM_COUNT, ATTR_GROUP, ATTR_USER, ATTR_SIZE, ATTR_DATETIME, ATTR_NAME, ATTR_LINK_TARGET)
    - _Requirements: 12.1, 12.2_

  - [ ] 1.2 Implement input sanitization function
    - Create `sanitize_input()` that strips or escapes shell injection characters (`;`, `&`, backticks, `$()`, `<`, `>`) from query string before processing
    - Ensure characters valid in XPath syntax (`[`, `]`, `@`, `/`, `*`, `(`, `)`, `'`, `=`, `!`, `<`, `>`) are preserved for parsing but never passed raw to shell commands
    - _Requirements: 11.1, 11.2_

- [ ] 2. Implement Query Parser
  - [ ] 2.1 Implement `parse_query()` function
    - Handle union operator `|` by splitting into sub-queries and setting UNION_QUERIES count
    - Classify query type as absolute (starts with `/`) or relative
    - Tokenize query into path steps by splitting on `/` and `//`
    - Assign axes: `child` for `/`, `descendant` for `//`, `parent` for `..`, `self` for `.`, `attribute` for `@`-prefixed steps
    - Extract predicate expressions from `[...]` brackets and associate with steps
    - Recognize wildcards: `*`, `@*`, `node()`
    - Validate syntax: check for unmatched brackets, empty steps, invalid characters; print error to stderr and exit 1 on failure
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 1.10, 1.11_

  - [ ]* 2.2 Write property test: Query parsing round-trip
    - **Property 1: Query parsing round-trip**
    - Generate valid query strings with varying steps, axes, predicates, wildcards, and unions; parse into AST, reconstruct, re-parse, and verify identical AST
    - **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.7, 1.8, 1.9**

  - [ ]* 2.3 Write property test: Invalid query yields error
    - **Property 16: Invalid query yields error**
    - Generate syntactically invalid queries (unmatched brackets, empty steps, malformed predicates); verify stderr output and exit code 1 with no stdout
    - **Validates: Requirements 1.11, 10.1, 10.4**

  - [ ]* 2.4 Write unit tests for parser
    - Test absolute vs relative classification
    - Test `//` descendant axis detection
    - Test predicate extraction from `[...]`
    - Test wildcard recognition (`*`, `@*`, `node()`)
    - Test union `|` splitting
    - Test error cases (unmatched brackets, empty steps)
    - _Requirements: 1.1–1.11_

- [ ] 3. Implement File System Adapter
  - [ ] 3.1 Implement `list_children()` function
    - Execute `ls -al` on a given directory path
    - Parse output into structured node data, skipping `.` and `..` entries
    - Populate node cache associative arrays for each child
    - _Requirements: 2.1, 2.4_

  - [ ] 3.2 Implement `get_attributes()` function
    - Parse `ls -al` output line into 8 attribute fields using `awk`
    - Map columns to: permissions (col 1), item-count (col 2), group (col 3), user (col 4), size (col 5), datetime (cols 6-8), name (col 9+)
    - Derive `@type` from first character of permissions (`d`=directory, `l`=symlink, `-`=file)
    - Handle both datetime formats: `Mon DD HH:MM` and `Mon DD  YYYY`
    - Detect symlinks via `l` prefix and record link target from `->` portion
    - _Requirements: 2.4, 2.5, 2.6, 2.7, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8_

  - [ ] 3.3 Implement `search_descendants()` function
    - Use `locate` command to search for matching nodes under a base path
    - Detect if `locate` is available; if not, fall back to `find` with warning to stderr
    - Filter locate results to only include paths under the specified base path
    - _Requirements: 2.2, 2.3, 12.3, 12.4_

  - [ ] 3.4 Implement `resolve_node()` and path normalization
    - Return node type: "file", "directory", "symlink", or "not_found"
    - Normalize paths containing `.`, `..`, `~` to absolute resolved paths
    - Detect symlink cycles to prevent infinite loops
    - _Requirements: 2.8, 11.3, 11.4_

  - [ ]* 3.5 Write property test: Attribute parsing completeness
    - **Property 2: Attribute parsing completeness**
    - Generate valid `ls -al` output lines covering both datetime formats and all node types; verify exactly 8 attribute fields extracted with correct values
    - **Validates: Requirements 2.4, 2.5, 2.6, 2.7, 8.1–8.8**

  - [ ]* 3.6 Write property test: Path normalization
    - **Property 3: Path normalization**
    - Generate paths with `.`, `..`, `~` components; verify normalized path is absolute with no relative components and refers to the same location
    - **Validates: Requirement 2.8**

  - [ ]* 3.7 Write property test: Locate/find equivalence
    - **Property 19: Locate/find equivalence**
    - For descendant queries, verify that `locate`-based results match `find`-based results
    - **Validates: Requirements 12.3, 12.4**

  - [ ]* 3.8 Write unit tests for File System Adapter
    - Create temp directory with known structure
    - Test `list_children()` output against expected children
    - Test `get_attributes()` for files, directories, symlinks
    - Test `search_descendants()` with locate and find fallback
    - Test path normalization with `.`, `..`, `~`
    - _Requirements: 2.1–2.8_

- [ ] 4. Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement Operator Engine
  - [ ] 5.1 Implement `eval_operator()` function
    - Arithmetic operators (`+`, `-`, `*`, `div`, `mod`): delegate to `bc` or `awk`
    - Comparison operators (`=`, `!=`, `<`, `<=`, `>`, `>=`): use bash `[[ ]]` for strings, `awk` or `bc` for numeric
    - Logical operators (`and`, `or`): combine boolean results
    - Auto-detect numeric vs string comparison based on operand types
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [ ]* 5.2 Write property test: Operator evaluation correctness
    - **Property 11: Operator evaluation correctness**
    - Generate pairs of numeric operands with arithmetic operators and verify mathematically correct results; generate comparison and logical operator pairs and verify correct boolean results
    - **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5**

  - [ ]* 5.3 Write unit tests for Operator Engine
    - Test each arithmetic operator with integer and decimal operands
    - Test each comparison operator with numeric and string operands
    - Test `and`/`or` logical operators
    - _Requirements: 5.1–5.5_

- [ ] 6. Implement Built-in Functions
  - [ ] 6.1 Implement `call_function()` dispatcher and positional functions
    - Implement `position()`, `last()`, `count()` using context position and node set size
    - _Requirements: 6.1_

  - [ ] 6.2 Implement string functions
    - Implement `string-length()`, `contains()`, `starts-with()`, `substring()`, `concat()`, `normalize-space()` delegating to `awk`/`sed`/`grep`
    - _Requirements: 6.2, 6.7_

  - [ ] 6.3 Implement numeric and boolean functions
    - Implement `sum()`, `floor()`, `ceiling()`, `round()`, `number()` delegating to `awk`/`bc`
    - Implement `boolean()`, `not()`, `true()`, `false()`
    - _Requirements: 6.3, 6.4, 6.7_

  - [ ] 6.4 Implement node functions and error handling
    - Implement `name()` returning node name, `node()` matching any node
    - Validate argument types and counts; print error to stderr and exit 1 on mismatch
    - _Requirements: 6.5, 6.6_

  - [ ]* 6.5 Write property test: String function correctness
    - **Property 12: String function correctness**
    - Generate input strings and verify each string function produces results consistent with XPath string function definitions
    - **Validates: Requirement 6.2**

  - [ ]* 6.6 Write property test: Numeric function correctness
    - **Property 13: Numeric function correctness**
    - Generate input numbers and verify each numeric function produces mathematically correct results
    - **Validates: Requirement 6.3**

  - [ ]* 6.7 Write unit tests for Built-in Functions
    - Test each positional, string, numeric, boolean, and node function
    - Test error handling for wrong argument types/counts
    - _Requirements: 6.1–6.7_

- [ ] 7. Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Implement Predicate Engine
  - [ ] 8.1 Implement `eval_predicate()` function
    - Numeric predicates: `[1]`, `[3]` — match by 1-based position
    - Position functions: resolve `last()` and `position()` within predicates
    - Arithmetic in predicates: evaluate expressions like `last()-1`
    - Attribute existence: `[@attr]` — check non-empty attribute value
    - Attribute equality: `[@attr='value']` — exact match
    - Attribute comparison: `[@attr>value]` — delegate to Operator Engine
    - Compound predicates: `and`/`or` — combine sub-predicate results
    - Delegate attribute lookups to File System Adapter, comparisons to Operator Engine, functions to Built-in Functions
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8_

  - [ ]* 8.2 Write property test: Positional predicate consistency
    - **Property 8: Positional predicate consistency**
    - For node sets of size N, verify `[1]` through `[N]` each return exactly one distinct node, `[last()]` returns same as `[N]`, and `position()` equals 1-based index
    - **Validates: Requirements 4.1, 4.2, 4.3, 4.4**

  - [ ]* 8.3 Write property test: Attribute predicate filtering correctness
    - **Property 9: Attribute predicate filtering correctness**
    - For node sets with attribute predicates (existence, equality, relational), verify filtered result contains exactly the matching nodes
    - **Validates: Requirements 4.5, 4.6, 4.7**

  - [ ]* 8.4 Write property test: Compound predicate logical correctness
    - **Property 10: Compound predicate logical correctness**
    - For compound `and`/`or` predicates, verify result equals intersection/union of individual sub-predicate results
    - **Validates: Requirement 4.8**

  - [ ]* 8.5 Write unit tests for Predicate Engine
    - Test numeric positional predicates
    - Test `last()`, `position()`, `last()-1`
    - Test attribute existence, equality, comparison predicates
    - Test compound `and`/`or` predicates
    - _Requirements: 4.1–4.8_

- [ ] 9. Implement Query Evaluator
  - [ ] 9.1 Implement `evaluate()` and `evaluate_step()` functions
    - Set initial context: root `/` for absolute queries, `$PWD` for relative queries
    - Iterate through AST steps, expanding node set per axis (child, descendant, parent, self, attribute)
    - For child axis: use `list_children()` and filter by step name
    - For descendant axis: use `search_descendants()`
    - For parent axis: replace each node with its parent directory
    - For self axis: keep node set unchanged
    - For attribute axis: retrieve attribute values via `get_attributes()`
    - Apply predicates after each step via `eval_predicate()`
    - Handle union `|` by evaluating sub-queries independently and merging results
    - Return empty result set (no output, exit 0) when no nodes match
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9_

  - [ ] 9.2 Implement wildcard matching in evaluator
    - `*` matches all child element nodes (files and directories)
    - `@*` matches all attribute values of current context node
    - `node()` matches any node of any kind
    - `//*` matches all element nodes in entire subtree
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [ ]* 9.3 Write property test: Self axis is identity
    - **Property 4: Self axis is identity**
    - For any node set, verify `.` returns the same node set unchanged
    - **Validates: Requirement 3.6**

  - [ ]* 9.4 Write property test: Parent axis correctness
    - **Property 5: Parent axis correctness**
    - For any non-root node, verify `..` returns the parent directory and the original node is a child of that parent
    - **Validates: Requirement 3.5**

  - [ ]* 9.5 Write property test: Child axis subset of descendant axis
    - **Property 6: Child axis subset of descendant axis**
    - For any directory and step name, verify child axis results are a subset of descendant axis results
    - **Validates: Requirements 3.3, 3.4, 7.1, 7.4**

  - [ ]* 9.6 Write property test: Union is set union
    - **Property 7: Union is set union**
    - For two sub-queries A and B, verify `A | B` equals the union of independent results
    - **Validates: Requirement 3.8**

  - [ ]* 9.7 Write property test: Wildcard attribute completeness
    - **Property 14: Wildcard attribute completeness**
    - For any node, verify `@*` returns all 8 defined attributes in key=value format
    - **Validates: Requirements 7.2, 9.3**

  - [ ]* 9.8 Write property test: Non-existent path yields empty result
    - **Property 15: Non-existent path yields empty result**
    - For queries referencing non-existent paths, verify no stdout output and exit code 0
    - **Validates: Requirements 3.9, 9.4, 10.2**

  - [ ]* 9.9 Write unit tests for Query Evaluator
    - Test absolute and relative query starting contexts
    - Test each axis type (child, descendant, parent, self, attribute)
    - Test predicate application during evaluation
    - Test union operator merging
    - Test wildcard matching (`*`, `@*`, `node()`, `//*`)
    - Test empty result for non-existent paths
    - _Requirements: 3.1–3.9, 7.1–7.4_

- [ ] 10. Implement Result Formatter
  - [ ] 10.1 Implement `format_results()` function
    - Node selections: output one full path per line to stdout
    - Single attribute selections (`@attr`): output attribute value
    - All-attribute selections (`@*`): output `key=value` format, one per line
    - Empty result set: no output, exit 0
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

  - [ ]* 10.2 Write unit tests for Result Formatter
    - Test path output format
    - Test single attribute output
    - Test `@*` key=value output
    - Test empty result produces no output
    - _Requirements: 9.1–9.4_

- [ ] 11. Wire components together and end-to-end integration
  - [ ] 11.1 Wire main entry point
    - Connect main function: sanitize input → parse_query → evaluate → format_results → output
    - Handle permission denied warnings (print to stderr, skip, continue)
    - Ensure exit codes: 0 for success/empty results, 1 for errors
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

  - [ ]* 11.2 Write property test: Command injection prevention
    - **Property 17: Command injection prevention**
    - Generate query strings with shell injection characters (`;`, `&`, backticks, `$()`, `<`, `>`); verify no injected commands execute
    - **Validates: Requirement 11.1**

  - [ ]* 11.3 Write property test: Read-only invariant
    - **Property 18: Read-only invariant**
    - Snapshot file system state before query execution, run queries, verify file system state is identical after
    - **Validates: Requirement 11.2**

  - [ ]* 11.4 Write integration tests
    - Create known directory tree in `/tmp` matching SPECs.md example
    - Test full end-to-end queries from spec examples: `/static/*`, `//static`, `/static/assets[1]`, `/static/assets[last()]`, `/static/assets[@size>3500]`, `//asset[@*]`, `//@size`
    - Test `//` queries with locate available and unavailable
    - Test symlinks, empty directories, special characters in names
    - Test permission-denied scenarios
    - _Requirements: 1.1–12.4_

- [ ] 12. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- All code lives in a single `xpath-dir` bash script; tests use the `bats` testing framework
