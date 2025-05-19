<h1>
<a href="https://github.com/smnandre/nmsize">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="nmsize-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="nmsize.png">
  <img width="460" alt="nmsize - Fast node_modules size scanner" src="nmsize.png" />
</picture>
</a>
</h1>

⚡ Lightweight CLI tool to find your `node_modules` folders and display their disk usage.

[![GitHub Repo](https://img.shields.io/badge/smnandre-nmsize-080408?style=flat-square&labelColor=181717)](https://github.com/smnandre/nmsize)
[![Tests](https://img.shields.io/badge/Tests-passing-080408?style=flat-square&labelColor=181717)](https://github.com/smnandre/nmsize/actions)
[![License](https://img.shields.io/badge/License-MIT-080408?style=flat-square&labelColor=181717)](https://github.com/smnandre/nmsize/blob/main/LICENSE)
[![Sponsor](https://img.shields.io/badge/Sponsor-me-080408?logo=github-sponsors&style=square&labelColor=181717)](https://github.com/sponsors/smnandre)

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

```bash

Option                     Description

-d, --depth NUM	            Maximum search depth (default: 10)
-s, --sort alpha|asc|desc   Sort results by name (alpha), ascending size (asc), or descending size (desc). Default is alpha.
-l, --limit NUM	            Limit the number of displayed results (default: no limit)
-i, --ignore PATTERN	    Ignore paths matching the given pattern (can be used multiple times)
--ignore-dots true|false    Exclude hidden directories (default: true)
-V, --version	            Display version information
-h, --help	                Show help message

```

### Example

```bash
nmsize ~/projects -d 5 -s desc --ignore-dots true
```

## License

[`nmsize`](https://github.com/smnandre/nmsize) is released by [Simon André](https://github.com/smnandre) under the [MIT License](LICENSE).
