# xpath-dir User Guide

## Table of Contents

- [User Guide](#user-guide)
  - [Path Expressions](#path-expressions)
  - [Axes](#axes)
  - [Predicates](#predicates)
  - [Wildcards](#wildcards)
  - [Union Operator](#union-operator)
  - [Attributes](#attributes)
  - [Operators](#operators)
  - [Built-in Functions](#built-in-functions)

---

## User Guide

### Path Expressions

`xpath-dir` uses path expressions to select nodes (files and directories) in the file system.

| Expression | Description | Example |
|---|---|---|
| `nodename` | Select nodes with this name | `static` |
| `/` | Select from the root (`/`) | `/etc/hosts` |
| `//` | Select matching descendants at any depth | `//assets` |
| `.` | Current node | `.` |
| `..` | Parent node | `..` |
| `@` | Select an attribute | `@size` |

Queries starting with `/` are **absolute** (rooted at `/`). All others are **relative** (rooted at `$PWD`).

```bash
# Absolute: list children of /etc
xpath-dir '/etc/*'

# Relative: list children of "src" in the current directory
xpath-dir 'src/*'

# Descendant: find all nodes named "config" anywhere under /home
xpath-dir '//home//config'

# Parent: get the parent of /var/log
xpath-dir '/var/log/..'
# /var
```

### Axes

Each step in a path expression uses an axis that controls the direction of traversal.

| Axis | Syntax | Description |
|---|---|---|
| child | `/name` | Direct children of the context node |
| descendant | `//name` | All descendants at any depth |
| parent | `..` | The parent directory |
| self | `.` | The node itself |
| attribute | `@attr` | An attribute of the node |

### Predicates

Predicates filter node sets using conditions inside `[...]` brackets.

#### Positional predicates

Select nodes by their 1-based position in the result set.

```bash
# First child of /var/log
xpath-dir '/var/log/*[1]'

# Last child
xpath-dir '/var/log/*[last()]'

# Second-to-last child
xpath-dir '/var/log/*[last()-1]'

# First three children
xpath-dir '/var/log/*[position()<4]'
```

#### Attribute predicates

Filter by attribute existence, value, or comparison.

```bash
# All nodes that have a "user" attribute (all nodes do, but demonstrates syntax)
xpath-dir '/home/*[@user]'

# Nodes owned by user "root"
xpath-dir '/etc/*[@user='root']'

# Files larger than 1 MB
xpath-dir '/var/log/*[@size>1000000]'

# Directories only
xpath-dir '/home/*[@type='directory']'
```

#### Compound predicates

Combine conditions with `and` / `or`.

```bash
# Files owned by root AND larger than 4096 bytes
xpath-dir '/etc/*[@user='root' and @size>4096]'

# Files owned by root OR owned by www-data
xpath-dir '/var/www/*[@user='root' or @user='www-data']'
```

### Wildcards

| Wildcard | Description | Example |
|---|---|---|
| `*` | Matches any file or directory | `/etc/*` |
| `@*` | Matches all attributes of a node | `/etc/hosts/@*` |
| `node()` | Matches any node of any kind | `/tmp/node()` |
| `//*` | All nodes in the entire subtree | `/home/user//*` |

```bash
# All children of /tmp
xpath-dir '/tmp/*'

# All attributes of /etc/hostname
xpath-dir '/etc/hostname/@*'

# Every single node under /var
xpath-dir '/var//*'
```

### Union Operator

Combine multiple queries with `|` to merge their results (duplicates removed).

```bash
# Get both /etc/hosts and /etc/hostname
xpath-dir '/etc/hosts | /etc/hostname'

# Combine two different directory listings
xpath-dir '/var/log/* | /tmp/*'
```

### Attributes

Every file and directory exposes 8 attributes derived from `ls -al` output:

| Attribute | Syntax | Description | Example value |
|---|---|---|---|
| `permissions` | `@permissions` | Full permission string | `-rwxr-xr-x` |
| `item-count` | `@item-count` | Hard-link count (files) or item count (dirs) | `3` |
| `group` | `@group` | Group owner | `www-data` |
| `user` | `@user` | User owner | `root` |
| `size` | `@size` | Size in bytes | `4096` |
| `datetime` | `@datetime` | Last modification date/time | `Apr 22 11:34` or `Jul 18 2025` |
| `name` | `@name` | File or directory name (basename) | `index.html` |
| `type` | `@type` | Node type | `file`, `directory`, or `symlink` |

Additionally for symlinks, `link-target` is available:

| Attribute | Syntax | Description | Example value |
|---|---|---|---|
| `link-target` | `@link-target` | Symlink destination path | `/usr/bin/python3` |

```bash
# Get the size of a file
xpath-dir '/var/log/syslog/@size'
# 234567

# Get the type of a node
xpath-dir '/usr/bin/python3/@type'
# symlink

# Show all attributes
xpath-dir '/etc/passwd/@*'
# permissions=-rw-r--r--
# item-count=1
# group=root
# user=root
# size=2345
# datetime=Mar 15 10:22
# name=passwd
# type=file
```

### Operators

Operators can be used inside predicates and function arguments.

#### Arithmetic operators

| Operator | Description | Example |
|---|---|---|
| `+` | Addition | `@size + 100` |
| `-` | Subtraction | `last() - 1` |
| `*` | Multiplication | `@size * 2` |
| `div` | Division | `@size div 1024` |
| `mod` | Modulus | `@size mod 512` |

#### Comparison operators

| Operator | Description | Example |
|---|---|---|
| `=` | Equal | `@user='root'` |
| `!=` | Not equal | `@type!='directory'` |
| `<` | Less than | `@size<1024` |
| `<=` | Less than or equal | `@size<=4096` |
| `>` | Greater than | `@size>1000000` |
| `>=` | Greater than or equal | `@item-count>=5` |

Numeric values are compared numerically; strings are compared lexicographically.

#### Logical operators

| Operator | Description | Example |
|---|---|---|
| `and` | Logical AND | `@size>0 and @type='file'` |
| `or` | Logical OR | `@user='root' or @user='admin'` |

### Built-in Functions

#### Positional functions

| Function | Description | Example |
|---|---|---|
| `position()` | 1-based index of the current node in the set | `*[position()<3]` |
| `last()` | Total number of nodes in the current set | `*[last()]` |
| `count(nodeset)` | Number of nodes in a node set | `count(...)` |

#### String functions

| Function | Description | Example |
|---|---|---|
| `string-length(str)` | Length of the string | `string-length(@name)` |
| `contains(str, sub)` | True if `str` contains `sub` | `contains(@name, '.log')` |
| `starts-with(str, prefix)` | True if `str` starts with `prefix` | `starts-with(@name, 'test')` |
| `substring(str, start [, len])` | Substring from 1-based position | `substring(@name, 1, 5)` |
| `concat(str1, str2, ...)` | Concatenate strings | `concat(@name, '.bak')` |
| `normalize-space(str)` | Trim and collapse whitespace | `normalize-space(@name)` |

#### Numeric functions

| Function | Description | Example |
|---|---|---|
| `sum(nodeset)` | Sum of numeric values | `sum(...)` |
| `floor(num)` | Largest integer ≤ num | `floor(3.7)` → `3` |
| `ceiling(num)` | Smallest integer ≥ num | `ceiling(3.2)` → `4` |
| `round(num)` | Nearest integer (half rounds up) | `round(3.5)` → `4` |
| `number(val)` | Convert to number (NaN if invalid) | `number('42')` → `42` |

#### Boolean functions

| Function | Description | Example |
|---|---|---|
| `boolean(val)` | Convert to boolean | `boolean(@size)` |
| `not(val)` | Logical negation | `not(@type='directory')` |
| `true()` | Returns `true` | `true()` |
| `false()` | Returns `false` | `false()` |

#### Node functions

| Function | Description | Example |
|---|---|---|
| `name(path)` | Basename of the node | `name(/etc/hosts)` |
| `node()` | Matches any node (wildcard) | `/tmp/node()` |

