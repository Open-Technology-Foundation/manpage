# manpage

Automatically generates and installs professional man pages from README.md files using Claude AI assistance. Transform your existing documentation into properly formatted man pages with a single command.

## Features

- **Automatic Conversion**: Transforms README.md files into properly formatted troff/man pages using Claude AI
- **Smart Installation**: Auto-detects installation context (user vs system-wide)
- **Path Intelligence**: Automatically finds README.md files in command directories
- **Standard Compliance**: Generates man pages following UNIX conventions with all standard sections
- **Validation Support**: Includes comprehensive test suite for man page validation
- **Error Recovery**: Robust error handling with informative messages
- **Color Output**: Terminal-aware colored output for better readability

## Installation

```bash
# Clone the repository
git clone https://github.com/Open-Technology-Foundation/manpage.git
cd manpage

# Make executable
chmod +x manpage

# Generate and install manpage's own man page (user-local)
./manpage generate -i manpage

# Or install system-wide
sudo ./manpage generate -i manpage
```

### Alternative Installation

```bash
# Direct download
wget https://raw.githubusercontent.com/Open-Technology-Foundation/manpage/main/manpage
chmod +x manpage

# Install to PATH
sudo mv manpage /usr/local/bin/
```

## Quick Start

```bash
# Generate a man page for your script
manpage generate ./myscript

# Generate and install in one command
manpage generate -i ./myscript

# View the generated man page
man myscript
```

## Usage

```
manpage [options] <command> [arguments]
```

### Commands

#### `generate` - Create man page from README.md

```bash
manpage generate [-i|--install] <command> [<readme>]
```

Converts a README.md file to a properly formatted man page using Claude AI.

**Arguments:**
- `<command>`: Path to the command/script to document (required)
- `<readme>`: Optional path to README.md file (defaults to command's directory)

**Options:**
- `-i, --install`: Install the man page immediately after generation

**Behavior:**
- Resolves full paths using `readlink -en` for reliability
- Searches for README.md in the command's directory if not specified
- Generates `.1` file in the same directory as the README
- Validates output by checking for `.TH` directive
- Exits with error if README.md not found or generation fails

**Output:**
- Creates `<command>.1` man page file
- Displays success message with file path
- Shows warnings for validation issues

#### `install` - Install generated man page

```bash
manpage install <command>
```

Installs a previously generated man page to the appropriate directory.

**Arguments:**
- `<command>`: Path to the command whose man page to install

**Installation Locations:**
- **System-wide**: `/usr/local/share/man/man1/` (when running as root/sudo)
- **User-local**: `~/.local/share/man/man1/` (for regular users)

**Behavior:**
- Auto-detects root/sudo context for installation type
- Creates destination directories if needed
- Updates man database (`mandb` or `makewhatis`)
- Checks MANPATH configuration for user installations
- Sets appropriate file permissions (644)

### Global Options

- `-h, --help`: Display help message and exit
- `-v, --verbose`: Enable verbose output (default)
- `-q, --quiet`: Disable verbose output
- `-V, --version`: Show version information

## Examples

### Basic Usage

```bash
# Generate man page for a script in current directory
manpage generate ./myscript

# Generate for a system command
manpage generate /usr/local/bin/mytool

# Generate with explicit README location
manpage generate mytool ~/projects/mytool/docs/README.md

# Generate and install immediately
manpage generate -i ./myscript
```

### Installation Examples

```bash
# Install for current user
manpage install ./myscript

# Install system-wide
sudo manpage install ./myscript

# Quiet mode installation
manpage -q install ./myscript
```

### Advanced Examples

```bash
# Generate man page for a symlinked command
manpage generate $(which mycommand)

# Generate from a specific branch's README
git show feature-branch:README.md > /tmp/README.md
manpage generate mycommand /tmp/README.md

# Batch processing
for script in scripts/*.sh; do
  manpage generate -i "$script"
done
```

## How It Works

### Architecture Overview

The `manpage` utility follows a clean, modular architecture:

1. **Path Resolution Layer**
   - Uses `readlink -en` for reliable path resolution
   - Handles symlinks, relative paths, and special characters
   - Falls back to alternative resolution methods if needed

2. **README Discovery Engine**
   - Intelligent search algorithm for locating README.md files
   - Checks command directory first, then accepts explicit paths
   - Validates file existence before processing

3. **AI Conversion Pipeline**
   - Constructs optimized prompts for Claude AI
   - Specifies troff formatting directives and man page structure
   - Includes all standard man page sections in proper order
   - Handles complex markdown formatting conversions

4. **Man Page Generation**
   - Creates section 1 (user commands) man pages
   - Validates output with `.TH` directive checks
   - Stores generated files alongside source README
   - Preserves original documentation structure

5. **Smart Installation System**
   - Auto-detects execution context (root/sudo vs user)
   - Creates necessary directory structures
   - Sets proper file permissions (644)
   - Updates man database for immediate availability

6. **Error Handling Framework**
   - Comprehensive error checking at each step
   - Informative error messages with exit codes
   - Graceful fallback mechanisms
   - Color-coded output for better visibility

## Requirements

### Core Dependencies

- **claude**: Claude CLI tool (required for AI conversion)
  ```bash
  # Check if installed
  which claude || echo "Claude CLI not found"
  ```

- **bash**: Version 4.0 or later
  ```bash
  # Check version
  bash --version
  ```

- **Standard UNIX utilities**:
  - `readlink` - Path resolution
  - `grep` - Pattern matching
  - `install` - File installation
  - `mandb` or `makewhatis` - Man database updates

### Optional Dependencies

- **groff**: For rendering and testing man pages locally
- **man**: For viewing generated man pages
- **shellcheck**: For validating bash script syntax

## Technical Details

### Man Page Format

Generated man pages follow the troff/groff format with standard sections:

1. **`.TH`** - Title header (name, section, date, version, manual)
2. **NAME** - Command name and one-line description
3. **SYNOPSIS** - Usage syntax with options
4. **DESCRIPTION** - Detailed explanation of functionality
5. **OPTIONS** - Command-line flags and parameters
6. **EXAMPLES** - Practical usage demonstrations
7. **EXIT STATUS** - Return codes and their meanings
8. **ENVIRONMENT** - Environment variables used
9. **FILES** - Configuration files and paths
10. **NOTES** - Additional important information
11. **BUGS** - Known issues or bug reporting
12. **SEE ALSO** - Related commands and documentation
13. **AUTHOR** - Creator and maintainer information
14. **COPYRIGHT** - License and legal notices

### Environment Configuration

#### MANPATH Configuration

For user-local installations, ensure your MANPATH includes the local directory:

```bash
# Add to ~/.bashrc or ~/.zshrc
export MANPATH="$HOME/.local/share/man:$MANPATH"

# Verify MANPATH
manpath

# Rebuild man database
mandb
```

#### Claude CLI Configuration

The script uses Claude with specific options:
- Model: Opus (configurable in script)
- Flags: `-p --dangerously-skip-permissions`
- Purpose: Bypasses interactive prompts for automation

### File Locations

- **Generated man pages**: `<readme_dir>/<command>.1`
- **User installation**: `~/.local/share/man/man1/`
- **System installation**: `/usr/local/share/man/man1/`
- **Man database**: Updated via `mandb` or `makewhatis`

## Troubleshooting

### Common Issues

#### "claude command not found"

The Claude CLI tool is required for AI conversion:

```bash
# Check if claude is installed
which claude

# Install instructions available at:
# https://github.com/anthropics/claude-cli
```

#### "Cannot find README.md"

The script searches for README.md in the command's directory:

```bash
# Check if README exists
ls -la /path/to/command/README.md

# Specify README path explicitly
manpage generate mycommand /custom/path/README.md
```

#### Man page not found after installation

For user installations, verify MANPATH configuration:

```bash
# Check current MANPATH
manpath

# Add local man directory
echo 'export MANPATH="$HOME/.local/share/man:$MANPATH"' >> ~/.bashrc
source ~/.bashrc

# Rebuild database
mandb
```

#### Permission denied errors

```bash
# For system installation, use sudo
sudo manpage install mycommand

# Check file permissions
ls -la ~/.local/share/man/man1/
```

#### Invalid man page format

```bash
# Validate generated man page
groff -man -T ascii mycommand.1 > /dev/null

# Check for .TH directive
head -n 1 mycommand.1
```

### Debugging Tips

```bash
# Enable verbose mode for detailed output
manpage -v generate mycommand

# Check generated file before installation
less mycommand.1

# Test man page rendering
man -l mycommand.1

# Verify installation location
find /usr/local/share/man ~/.local/share/man -name "mycommand.1" 2>/dev/null
```

## Testing

### Test Suite

The project includes a comprehensive test framework:

```bash
# Run complete test suite
./test/test_manpage.sh

# Run with verbose output
./test/test_manpage.sh -v

# Validate specific man page
./test/validate_man.sh mycommand.1

# Validate with detailed output
./test/validate_man.sh -v mycommand.1
```

### Test Coverage

The test suite validates:

- **Core Functionality**
  - Man page generation from README
  - Installation to user and system directories
  - Path resolution and discovery

- **Edge Cases**
  - Paths with spaces and special characters
  - Symlinks and relative paths
  - Missing or invalid README files
  - Non-existent commands

- **Man Page Validation**
  - Proper troff/groff syntax
  - Required sections presence
  - Format compliance
  - Rendering without errors

- **Error Handling**
  - Missing dependencies
  - Permission issues
  - Invalid arguments
  - Claude CLI failures

### Running Tests

```bash
# Quick validation
shellcheck -x manpage

# Full test run
cd test && ./test_manpage.sh

# Specific test category
./test/test_manpage.sh --category=generation
```

## Development

### Project Structure

```
manpage/
├── manpage                # Main executable script
├── README.md              # Project documentation (this file)
├── LICENSE                # GPL-3 license file
├── test/                  # Test suite directory
│   ├── test_manpage.sh    # Comprehensive test runner
│   ├── validate_man.sh    # Man page format validator
│   └── fixtures/          # Test data and examples
│       ├── sample.md      # Example README files
│       └── expected/      # Expected output files
└── manpage.1              # Generated man page for manpage itself
```

### Contributing

#### Development Workflow

1. **Fork and Clone**
   ```bash
   git clone https://github.com/yourusername/manpage.git
   cd manpage
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature
   ```

3. **Make Changes**
   - Follow [BASH-CODING-STANDARD](https://github.com/Open-Technology-Foundation/bash-coding-standard)
   - Maintain 2-space indentation
   - Use `set -euo pipefail` for error handling
   - Document new features in README

4. **Test Thoroughly**
   ```bash
   # Syntax check
   shellcheck -x manpage

   # Run test suite
   ./test/test_manpage.sh

   # Test your changes
   ./manpage generate -i testscript
   ```

5. **Submit Pull Request**
   - Clear description of changes
   - Reference any related issues
   - Include test results

#### Code Style Guidelines

- **Bash Version**: Target bash 4.0+ compatibility
- **Error Handling**: Use proper exit codes and error messages
- **Functions**: Prefix internal functions with underscore
- **Variables**: Use uppercase for globals, lowercase for locals
- **Comments**: Document complex logic and non-obvious code

#### Testing Guidelines

- Add tests for new features
- Update existing tests when modifying behavior
- Ensure 100% pass rate before submitting PR
- Include edge cases and error conditions

### API Stability

The command-line interface is considered stable. Any breaking changes will:
- Be documented in CHANGELOG
- Increment major version number
- Provide migration guide

### Release Process

1. Update version in script header
2. Update README.md version reference
3. Generate new man page
4. Create git tag
5. Push to repository

## Support

### Getting Help

- **Documentation**: Read this README and generated man pages
- **Issues**: [GitHub Issues](https://github.com/Open-Technology-Foundation/manpage/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Open-Technology-Foundation/manpage/discussions)

### Reporting Bugs

When reporting issues, please include:
- Operating system and version
- Bash version (`bash --version`)
- Claude CLI version
- Complete error output
- Steps to reproduce

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3).

Key points:
- Free to use, modify, and distribute
- Source code must remain open
- Modifications must use same license
- No warranty provided

See [LICENSE](LICENSE) file for full details.

## Credits

### Author

Created and maintained by the [Indonesian Open Technology Foundation](https://yatti.id) for automating man page generation from existing documentation.

