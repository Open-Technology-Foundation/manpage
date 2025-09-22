# manpage

A utility to automatically generate and install UNIX man pages from README.md files using AI assistance.

## Installation

```bash
# Clone the repository or download the script
git clone https://github.com/yourusername/manpage.git
cd manpage
chmod +x manpage

# Install manpage's own man page
./manpage generate -i manpage

# Or install system-wide
sudo ./manpage generate -i manpage
```

## Usage

### Generate a man page

```bash
# Generate man page for a command (looks for README.md in command's directory)
manpage generate mycommand

# Generate using a specific README file
manpage generate mycommand /path/to/README.md

# Generate and install in one step
manpage generate -i mycommand
```

### Install a man page

```bash
# Install existing man page (auto-detects user vs system installation)
manpage install mycommand

# Install as root for system-wide access
sudo manpage install mycommand
```

## Command Reference

### `manpage generate [-i|--install] <command> [<readme>]`

Generate a man page for `<command>` from its README.md file.

**Arguments:**
- `<command>`: Path to the command/script to document
- `<readme>`: Optional path to README.md file (defaults to command's directory)

**Options:**
- `-i, --install`: Install the man page immediately after generation

**Behavior:**
- Uses `readlink -en` to resolve full paths
- Stores the generated `.1` file in the same directory as the README
- Exits with error if no README.md is found

### `manpage install <command>`

Install a previously generated man page.

**Arguments:**
- `<command>`: Path to the command whose man page to install

**Behavior:**
- Automatically detects installation location:
  - **System-wide** (`/usr/local/share/man/man1/`) when running as root or with sudo
  - **User-local** (`~/.local/share/man/man1/`) for regular users
- Updates the man database after installation

## Examples

```bash
# Generate man page for a script in current directory
manpage generate ./myscript

# Generate for a system command
manpage generate /usr/local/bin/mytool

# Generate with explicit README location
manpage generate mytool ~/projects/mytool/docs/README.md

# Generate and install immediately
manpage generate -i ./myscript

# Install for current user
manpage install ./myscript

# Install system-wide
sudo manpage install ./myscript
```

## How It Works

1. **Path Resolution**: Uses `readlink -en` to resolve full paths for commands and README files
2. **README Discovery**: Looks for README.md in the command's directory by default, or uses explicitly specified path
3. **AI Conversion**: Uses Claude CLI with optimized prompts to convert README content to proper troff/man format
4. **Man Page Generation**: Creates a `.1` file in the README's directory with standard man page sections
5. **Smart Installation**: Automatically detects whether running as root/sudo to choose between system-wide (`/usr/local/share/man/man1/`) or user-local (`~/.local/share/man/man1/`) installation
6. **Database Update**: Updates the man database after installation for immediate availability

## Requirements

- **claude**: Claude CLI tool must be installed and configured
- **bash**: Version 4.0 or later
- Standard UNIX utilities: `readlink`, `grep`, `install`, `mandb`/`makewhatis`
- **groff**: For rendering and validating man pages

## Man Page Sections

Generated man pages are properly formatted with standard sections in conventional order:
- **NAME** - Command name and brief description
- **SYNOPSIS** - Usage syntax
- **DESCRIPTION** - Detailed functionality
- **OPTIONS** - Command-line flags and parameters
- **EXAMPLES** - Practical usage examples
- **EXIT STATUS** - Return codes and their meanings
- **ENVIRONMENT** - Environment variables
- **FILES** - Related configuration files and paths
- **NOTES** - Additional important information
- **BUGS** - Known issues or where to report them
- **SEE ALSO** - References to related commands
- **AUTHOR** - Creator/maintainer information
- **COPYRIGHT** - License and legal information

## Environment

The script respects standard UNIX conventions:
- Man pages are installed to section 1 (user commands)
- User installations may require adding to MANPATH:
  ```bash
  export MANPATH="$HOME/.local/share/man:$MANPATH"
  ```

## Troubleshooting

### "claude command not found"
Install the Claude CLI tool first.

### "Cannot find README.md"
Ensure README.md exists in the same directory as your command, or specify the path explicitly.

### Man page not found after installation
For user installations, ensure `~/.local/share/man` is in your MANPATH.

## Testing

The project includes a comprehensive test suite:

```bash
# Run all tests
./test/test_manpage.sh

# Validate a specific man page
./test/validate_man.sh [-v] generated.1
```

The test suite covers:
- Basic functionality (generate, install)
- Path resolution (relative, absolute, symlinks)
- Error handling (missing files, invalid commands)
- Edge cases (spaces in paths, special characters)
- Man page validation (structure, content, groff syntax)

## Development

### Project Structure
```
manpage/
├── manpage             # Main script
├── README.md          # This file
├── CLAUDE.md          # AI assistant instructions
├── test/              # Test suite
│   ├── test_manpage.sh    # Main test runner
│   ├── validate_man.sh    # Man page validator
│   └── fixtures/          # Test data
└── manpage.1          # Generated man page
```

### Contributing

1. Run tests before submitting changes
2. Follow the existing bash coding standards (see BASH-CODING-STANDARD.md)
3. Update tests when adding new features
4. Ensure generated man pages pass validation

## License

MIT License - See LICENSE file for details

## Author

Created for automating man page generation from existing documentation.

## Version

Current version: 1.0.0