# xpath-dir

Query your Linux file system using XPath syntax — right from the terminal.

`xpath-dir` is a standalone Bash script that lets you navigate files, directories, and their attributes using the familiar [XPath](https://www.w3.org/TR/xpath/) path expression language. Instead of XML nodes, it operates on your file system tree.

```bash
# List direct children of /var/log
xpath-dir '/var/log/*'

# Get the size of a specific file
xpath-dir '/etc/hostname/@size'

# Find files larger than 100KB in a directory
xpath-dir '/var/log/*[@size>100000]'
```

> Disclaimer: The entiere project was built using Agentic-AI (Kiro) based on the specification in [SPECs.](SPECs.md)
> The project is still work-in-progress, not all features are working correctly yet.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Output Format](#output-format)
- [Exit Codes](#exit-codes)
- [Performance Tips](#performance-tips)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- XPath-like query syntax adapted for file systems
- Supports absolute and relative path queries
- Predicates with attribute filtering, positional selection, and compound logic
- 8 file/directory attributes queryable via `@attr` syntax
- 20+ built-in functions (positional, string, numeric, boolean, node)
- Arithmetic, comparison, and logical operators
- Union queries with `|`
- Wildcard matching (`*`, `@*`, `node()`)
- Uses `locate` for fast descendant searches (falls back to `find`)
- Symlink detection with cycle prevention
- Input sanitization against shell injection
- Read-only — never modifies your file system

## Requirements

- **Bash 4.0+** (for associative array support)
- Standard Unix utilities: `ls`, `awk`, `sed`, `grep`, `bc`, `find`
- **Optional:** `locate` (for faster `//` descendant queries)

Most Linux distributions ship all of these out of the box.

## Installation

### Using the install script

```bash
git clone https://github.com/<your-username>/xpath-dir.git
cd xpath-dir
./install.sh
```

This copies `xpath-dir` to `/usr/bin` and sets executable permissions. It will prompt for `sudo` if needed.

### Manual install

```bash
sudo cp xpath-dir /usr/bin/xpath-dir
sudo chmod 755 /usr/bin/xpath-dir
```

### Run without installing

```bash
chmod +x xpath-dir
./xpath-dir '<query>'
```

---

## Quick Start

Given this directory tree:

```
~/project
├── app
│   └── index.php
├── build.sh
├── LICENSE
├── README.md
├── run.sh
└── static
    ├── assets
    │   ├── css/
    │   ├── fonts/
    │   └── js/
    ├── favicon.ico
    ├── images
    │   ├── banner.png
    │   ├── pic01.jpg
    │   └── logo.png
    └── index.html
```

```bash
# List everything in static/
xpath-dir '/home/user/project/static/*'
# /home/user/project/static/assets
# /home/user/project/static/favicon.ico
# /home/user/project/static/images
# /home/user/project/static/index.html

# Find all .png files anywhere under the project
xpath-dir '//project//*.png'

# Get the owner of build.sh
xpath-dir '/home/user/project/build.sh/@user'

# Show all attributes of README.md
xpath-dir '/home/user/project/README.md/@*'
# permissions=-rwxr-xr-x
# item-count=1
# group=user
# user=user
# size=1970
# datetime=Jul 18 2025
# name=README.md
# type=file
```

---

## Output Format

| Query type | Output |
|---|---|
| Node selection | One absolute path per line |
| Single attribute (`@attr`) | Attribute value (one per line if multiple nodes) |
| All attributes (`@*`) | `key=value` format, one attribute per line |
| Empty result | No output (silent) |

---

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | Success (including empty result sets) |
| `1` | Error (syntax error, missing dependency, invalid query) |

Errors and warnings are printed to `stderr`. Warnings (e.g., permission denied on a subdirectory) do not stop execution — the tool skips inaccessible nodes and continues.

---

## Performance Tips

- **Install `locate`** — descendant queries (`//`) use `locate` for near-instant lookups across the entire file system. Without it, `find` is used as a fallback, which can be significantly slower on large trees.
  ```bash
  # Debian/Ubuntu
  sudo apt install mlocate
  sudo updatedb

  # RHEL/Fedora
  sudo dnf install mlocate
  sudo updatedb
  ```
- **Be specific** — narrow your queries with absolute paths and predicates to reduce the search space.
- **Avoid `//*`** on large trees — selecting every node from root can be slow even with `locate`.

---

## Security

- `xpath-dir` is **read-only** — it never creates, modifies, or deletes files.
- Input is **sanitized** — shell injection characters (`` ` ``, `;`, `&`, `$`) are stripped before processing.
- Values passed to shell commands are **escaped** via `printf %q`.
- Symlink cycles are detected and capped at 40 hops (POSIX SYMLOOP_MAX).

---

## Contributing

Contributions are welcome. Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

<!--
TODO: Not implemented yet.
Tests use the [bats](https://github.com/bats-core/bats-core) testing framework. Run them with:

```bash
bats tests/
```
-->

