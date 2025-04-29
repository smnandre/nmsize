<h1>
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="nmsize-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="nmsize.png">
  <img width="460" alt="nmsize - Fast node_modules size scanner" src="nmsize.png" />
</picture>
</h1>

⚡ A lightweight CLI tool to list all `node_modules` folders and display their disk usage with a quick summary.

[![Tests](https://github.com/smnandre/nmsize/actions/workflows/test.yml/badge.svg?color=4AEC1E)](https://github.com/smnandre/nmsize/actions)
[![Version](https://img.shields.io/github/v/release/smnandre/nmsize?color=E16601)](https://github.com/smnandre/nmsize/releases)
[![License](https://img.shields.io/github/license/smnandre/nmsize?color=FA190F)](https://github.com/smnandre/nmsize/blob/main/LICENSE)

## Installation

### Homebrew

```bash
# Add the tap
brew tap smnandre/homebrew-nmsize
# Install nmsize
brew install smnandre/nmsize
```

### From Source

```bash
git clone https://github.com/smnandre/nmsize.git
cd nmsize
chmod +x nmsize.sh
```

## Usage

### Scan `node_modules`

```bash
nmsize [OPTIONS] [DIRECTORY]
```

If no directory is specified, the current directory `.` is used.

### Options

```
Option	                    Description
-d, --depth NUM	            Maximum search depth (default: 10)
-s, --sort alpha|asc|desc   Sort results by name (alpha), ascending size (asc), or descending size (desc). Default is alpha.
-l, --limit NUM	            Limit the number of displayed results (default: no limit)
-i, --ignore PATTERN	    Ignore paths matching the given pattern (can be used multiple times)
--ignore-dots true|false    Exclude hidden directories (default: true)
-V, --version	            Display version information
-h, --help	            Show help message
```

### Example

```bash
nmsize ~/projects -d 5 -s desc --ignore-dots true
```

## License

This Formula is released under the [MIT License](LICENSE).
