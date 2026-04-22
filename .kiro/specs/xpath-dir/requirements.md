# Requirements Document

## Introduction

xpath-dir is an executable Linux bash shell script that queries file directory structures using XPath-like syntax adapted from the W3C XPath specification. The file system is treated as a tree of nodes: directories are branch nodes, files are leaf nodes, and file metadata from `ls -al` serves as attributes. The script accepts a single query string argument, parses it, evaluates it against the live file system, and outputs matching nodes or attribute values to stdout.

## Glossary

- **Script**: The xpath-dir bash shell script executable
- **Parser**: The Query Parser component that tokenizes and parses query strings into an AST
- **Evaluator**: The Query Evaluator component that walks the AST and resolves path steps against the file system
- **Adapter**: The File System Adapter component that abstracts OS-level file system interactions
- **Predicate_Engine**: The component that evaluates predicate expressions within square brackets
- **Operator_Engine**: The component that evaluates arithmetic, comparison, and logical operators
- **Function_Engine**: The component implementing XPath built-in functions for the file system context
- **Formatter**: The Result Formatter component that formats output to stdout
- **Node**: A file, directory, symlink, or root element in the file system tree
- **AST**: Abstract Syntax Tree — the internal structured representation of a parsed query
- **Predicate**: A filter expression enclosed in square brackets that narrows a node set
- **Axis**: The direction of navigation in a path step (child, descendant, parent, self, attribute)
- **Attribute**: A metadata property of a node derived from `ls -al` output columns

## Requirements

### Requirement 1: Query Parsing

**User Story:** As a user, I want to write XPath-like query strings to navigate the file system, so that I can select files and directories using familiar path expression syntax.

#### Acceptance Criteria

1. WHEN a query string is provided, THE Parser SHALL tokenize the string into path steps separated by `/` or `//`
2. WHEN a path step contains a `[...]` bracket expression, THE Parser SHALL extract the predicate expression and associate it with that step
3. WHEN a query starts with `/`, THE Parser SHALL classify the query type as absolute
4. WHEN a query does not start with `/`, THE Parser SHALL classify the query type as relative
5. WHEN a path step is `..`, THE Parser SHALL assign the parent axis to that step
6. WHEN a path step is `.`, THE Parser SHALL assign the self axis to that step
7. WHEN a path step is preceded by `//`, THE Parser SHALL assign the descendant axis to that step
8. WHEN a path step starts with `@`, THE Parser SHALL assign the attribute axis to that step
9. WHEN a query contains the `|` union operator, THE Parser SHALL split the query into separate sub-queries for independent evaluation
10. WHEN a query contains wildcards `*`, `@*`, or `node()`, THE Parser SHALL recognize each as a valid wildcard step matching any element node, any attribute node, or any node of any kind respectively
11. IF a query string has invalid syntax such as unmatched brackets, empty steps, or invalid characters, THEN THE Parser SHALL print an error message to stderr and the Script SHALL exit with code 1

### Requirement 2: File System Interaction

**User Story:** As a user, I want the script to read file system information using standard Linux tools, so that I can get accurate and up-to-date results from the live file system.

#### Acceptance Criteria

1. WHEN listing child nodes of a directory, THE Adapter SHALL execute `ls -al` on that directory and parse the output into structured node data
2. WHEN a path step uses the `//` descendant axis, THE Adapter SHALL use the `locate` command to search for matching nodes
3. IF the `locate` command is not available or the locate database is not updated, THEN THE Adapter SHALL fall back to the `find` command and print a warning to stderr
4. WHEN retrieving attributes for a node, THE Adapter SHALL parse the `ls -al` output into the following attribute fields: permissions, item-count, group, user, size, datetime, name, and type
5. WHEN a node is a symlink, THE Adapter SHALL detect the symlink via the `l` prefix in the permissions field and record the link target
6. WHEN the `ls -al` datetime column uses the format `Mon DD HH:MM`, THE Adapter SHALL parse the datetime correctly
7. WHEN the `ls -al` datetime column uses the format `Mon DD  YYYY`, THE Adapter SHALL parse the datetime correctly
8. WHEN resolving a path containing `.`, `..`, or `~`, THE Adapter SHALL normalize the path to an absolute resolved path with no relative components remaining


### Requirement 3: Query Evaluation

**User Story:** As a user, I want the script to evaluate my query step by step against the file system, so that I can navigate directory trees and filter results using predicates.

#### Acceptance Criteria

1. WHEN evaluating an absolute query, THE Evaluator SHALL begin evaluation from the root node `/`
2. WHEN evaluating a relative query, THE Evaluator SHALL begin evaluation from the current working directory
3. WHEN processing a path step with the child axis, THE Evaluator SHALL expand the current node set to include only direct children matching the step name
4. WHEN processing a path step with the descendant axis, THE Evaluator SHALL expand the current node set to include all descendant nodes matching the step name
5. WHEN processing a path step with the parent axis (`..`), THE Evaluator SHALL replace each node in the current set with its parent directory
6. WHEN processing a path step with the self axis (`.`), THE Evaluator SHALL keep the current node set unchanged
7. WHEN a path step has an associated predicate, THE Evaluator SHALL apply the predicate to filter the candidate node set before proceeding to the next step
8. WHEN a query contains the `|` union operator, THE Evaluator SHALL evaluate each sub-query independently and merge the results into a single node set
9. WHEN a path step matches no nodes in the file system, THE Evaluator SHALL return an empty result set with no output and exit code 0

### Requirement 4: Predicate Evaluation

**User Story:** As a user, I want to use predicates in square brackets to filter nodes by position, attribute existence, or attribute value, so that I can narrow down query results precisely.

#### Acceptance Criteria

1. WHEN a predicate is a numeric literal such as `[1]` or `[3]`, THE Predicate_Engine SHALL select the node at that 1-based position in the current node set
2. WHEN a predicate uses `last()`, THE Predicate_Engine SHALL resolve `last()` to the total number of nodes in the current set
3. WHEN a predicate uses `position()`, THE Predicate_Engine SHALL resolve `position()` to the 1-based index of the current node being evaluated
4. WHEN a predicate contains an arithmetic expression such as `last()-1`, THE Predicate_Engine SHALL evaluate the arithmetic and use the result as a positional index
5. WHEN a predicate tests attribute existence such as `[@user]`, THE Predicate_Engine SHALL select nodes that have a non-empty value for the specified attribute
6. WHEN a predicate tests attribute equality such as `[@user='John']`, THE Predicate_Engine SHALL select nodes whose specified attribute matches the given value exactly
7. WHEN a predicate tests attribute comparison such as `[@size>3500]`, THE Predicate_Engine SHALL select nodes whose specified attribute satisfies the comparison
8. WHEN a predicate contains compound expressions using `and` or `or`, THE Predicate_Engine SHALL evaluate both sub-expressions and combine results using the specified logical operator

### Requirement 5: Operator Evaluation

**User Story:** As a user, I want to use arithmetic, comparison, and logical operators in my queries, so that I can build complex filter expressions.

#### Acceptance Criteria

1. WHEN evaluating arithmetic operators `+`, `-`, `*`, `div`, or `mod`, THE Operator_Engine SHALL delegate computation to `bc` or `awk` and return the numeric result
2. WHEN evaluating comparison operators `=`, `!=`, `<`, `<=`, `>`, or `>=`, THE Operator_Engine SHALL compare the operands and return a boolean result
3. WHEN evaluating logical operators `or` and `and`, THE Operator_Engine SHALL combine boolean operands and return the logical result
4. WHEN both operands of a comparison are numeric, THE Operator_Engine SHALL perform a numeric comparison
5. WHEN one or both operands of a comparison are non-numeric strings, THE Operator_Engine SHALL perform a string comparison

### Requirement 6: Built-in Functions

**User Story:** As a user, I want to use built-in functions for string manipulation, numeric computation, boolean logic, and positional queries, so that I can write expressive queries.

#### Acceptance Criteria

1. THE Function_Engine SHALL support positional functions: `position()`, `last()`, and `count()`
2. THE Function_Engine SHALL support string functions: `string-length()`, `contains()`, `starts-with()`, `substring()`, `concat()`, and `normalize-space()`
3. THE Function_Engine SHALL support numeric functions: `sum()`, `floor()`, `ceiling()`, `round()`, and `number()`
4. THE Function_Engine SHALL support boolean functions: `boolean()`, `not()`, `true()`, and `false()`
5. THE Function_Engine SHALL support node functions: `name()` returning the node name and `node()` matching any node of any kind
6. WHEN a function receives arguments of an incorrect type or count, THE Function_Engine SHALL report an error to stderr and the Script SHALL exit with code 1
7. WHERE computation can be delegated to `awk`, `sed`, or `grep`, THE Function_Engine SHALL use those tools rather than custom bash implementations

### Requirement 7: Wildcard Matching

**User Story:** As a user, I want to use wildcards to match unknown nodes and attributes, so that I can write flexible queries without knowing exact names.

#### Acceptance Criteria

1. WHEN a path step is `*`, THE Evaluator SHALL match all child element nodes (files and directories) of the current context
2. WHEN a path step is `@*`, THE Evaluator SHALL match all attribute values of the current context node
3. WHEN a path step is `node()`, THE Evaluator SHALL match all nodes of any kind in the current context
4. WHEN `//` is combined with `*` as `//*`, THE Evaluator SHALL match all element nodes in the entire file system tree from the current context downward

### Requirement 8: Attribute Mapping

**User Story:** As a user, I want to access file metadata as named attributes using `@` syntax, so that I can filter and retrieve specific file properties.

#### Acceptance Criteria

1. THE Adapter SHALL map `@permissions` to column 1 of `ls -al` output representing the permission string
2. THE Adapter SHALL map `@item-count` to column 2 of `ls -al` output representing the hard link or item count
3. THE Adapter SHALL map `@group` to column 3 of `ls -al` output representing the group name
4. THE Adapter SHALL map `@user` to column 4 of `ls -al` output representing the user name
5. THE Adapter SHALL map `@size` to column 5 of `ls -al` output representing the file size in bytes
6. THE Adapter SHALL map `@datetime` to columns 6 through 8 of `ls -al` output representing the last modification date and time
7. THE Adapter SHALL map `@name` to column 9 of `ls -al` output representing the file or directory name
8. THE Adapter SHALL derive `@type` from the first character of the permissions field, mapping `d` to directory, `l` to symlink, and `-` to file

### Requirement 9: Result Formatting

**User Story:** As a user, I want query results formatted clearly on stdout, so that I can use the output in pipelines or read it directly.

#### Acceptance Criteria

1. WHEN the query selects nodes, THE Formatter SHALL output one full path per line to stdout
2. WHEN the query selects a single attribute via `@attr`, THE Formatter SHALL output the attribute value to stdout
3. WHEN the query selects all attributes via `@*`, THE Formatter SHALL output all attributes in `key=value` format, one per line
4. WHEN the query result set is empty, THE Formatter SHALL produce no output and the Script SHALL exit with code 0

### Requirement 10: Error Handling

**User Story:** As a user, I want clear error messages when something goes wrong, so that I can correct my query or understand the issue.

#### Acceptance Criteria

1. IF a query string has invalid syntax, THEN THE Script SHALL print a descriptive error message to stderr and exit with code 1
2. IF a path step resolves to a non-existent file system path, THEN THE Evaluator SHALL return an empty result set and the Script SHALL exit with code 0
3. IF the user lacks read permission on a directory or file, THEN THE Adapter SHALL print a warning to stderr for the inaccessible path, skip that path, and continue evaluation with remaining accessible paths
4. IF a predicate contains an unsupported function or malformed expression, THEN THE Script SHALL print an error message to stderr identifying the predicate and exit with code 1

### Requirement 11: Security

**User Story:** As a system administrator, I want the script to be safe to run, so that it cannot be exploited for command injection or unintended file system modifications.

#### Acceptance Criteria

1. THE Script SHALL sanitize the query string before passing any part of it to shell commands to prevent command injection via characters such as `;`, `&`, backticks, `$()`, `<`, `>`, `(`, or `)`
2. THE Script SHALL operate in a strictly read-only manner and never modify the file system
3. WHEN following symlinks during evaluation, THE Script SHALL detect symlink cycles and stop traversal to prevent infinite loops
4. WHEN navigating with `..`, THE Script SHALL respect OS-level permission boundaries and not grant access beyond the user's existing permissions

### Requirement 12: Dependencies and Runtime

**User Story:** As a user, I want the script to run on standard Linux systems with minimal setup, so that I can use it without installing special software.

#### Acceptance Criteria

1. THE Script SHALL require bash version 4.0 or higher for associative array support
2. THE Script SHALL require the following standard Linux tools: `ls`, `awk`, `sed`, `grep`, `bc`, and `find`
3. WHERE the `locate` command is available, THE Script SHALL use it for `//` descendant searches for improved performance
4. WHERE the `locate` command is not available, THE Script SHALL fall back to `find` without loss of correctness
