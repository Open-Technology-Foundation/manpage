# multicmd

Advanced multi-feature command with extensive documentation for comprehensive testing.

## Synopsis

`multicmd [global-options] command [command-options]`

## Description

Multicmd is a sophisticated command-line tool that demonstrates complex man page generation.
It supports multiple subcommands, global and local options, and extensive configuration.

This tool is designed to test the full capabilities of the manpage generator, including
proper formatting of complex structures, nested options, and multiple sections.

## Commands

### init
Initialize a new project with default configuration.

Usage: `multicmd init [options] PROJECT_NAME`

Options:
- `--template TEMPLATE` - Use a specific project template
- `--no-git` - Skip git repository initialization

### build
Build the project using the configuration file.

Usage: `multicmd build [options]`

Options:
- `--clean` - Clean before building
- `--parallel N` - Use N parallel jobs
- `--profile PROFILE` - Build profile (debug|release)

### deploy
Deploy the built project to the specified environment.

Usage: `multicmd deploy [options] ENVIRONMENT`

Options:
- `--dry-run` - Simulate deployment without changes
- `--force` - Force deployment even with warnings

## Global Options

- `-v, --verbose` - Enable verbose output
- `-q, --quiet` - Suppress non-error output
- `--config FILE` - Use specified configuration file
- `--no-color` - Disable colored output
- `--debug` - Enable debug mode with trace output

## Configuration

Multicmd uses a hierarchical configuration system:

1. Command-line arguments (highest priority)
2. Environment variables
3. User configuration file (`~/.multicmdrc`)
4. System configuration file (`/etc/multicmd.conf`)
5. Built-in defaults (lowest priority)

## Environment

- `MULTICMD_HOME` - Base directory for multicmd operations
- `MULTICMD_CONFIG` - Path to configuration file
- `MULTICMD_CACHE` - Cache directory location
- `MULTICMD_LOG_LEVEL` - Logging verbosity (ERROR|WARN|INFO|DEBUG)

## Examples

Initialize a new project:
```bash
multicmd init myproject
multicmd init --template nodejs webapp
```

Build with custom options:
```bash
multicmd build
multicmd --verbose build --parallel 4
multicmd --config custom.conf build --profile release
```

Deploy to staging:
```bash
multicmd deploy staging
multicmd deploy --dry-run production
```

Complex workflow:
```bash
multicmd --debug init myapp && \
  cd myapp && \
  multicmd build --clean && \
  multicmd deploy --force staging
```

## Files

- `~/.multicmdrc` - User configuration file (YAML format)
- `/etc/multicmd.conf` - System-wide configuration
- `./.multicmd.yml` - Project-specific configuration
- `~/.multicmd/cache/` - Cache directory
- `~/.multicmd/logs/` - Log files directory

## Exit Status

- 0 - Success
- 1 - General error
- 2 - Invalid command-line arguments
- 3 - Configuration error
- 4 - Build failure
- 5 - Deployment failure
- 126 - Command cannot execute
- 127 - Command not found

## Diagnostics

Multicmd provides detailed error messages and diagnostic information.
Use `--debug` flag for trace-level output.

Common error messages:
- "Configuration file not found" - Check MULTICMD_CONFIG path
- "Invalid project structure" - Ensure proper project initialization
- "Build failed" - Check build logs in ~/.multicmd/logs/

## Notes

This command requires an active internet connection for certain operations.
Proxy settings are respected from standard environment variables (HTTP_PROXY, HTTPS_PROXY).

## Bugs

Known issues:
- Parallel builds may fail on systems with limited memory
- Unicode filenames may not display correctly on some terminals

Report bugs to: https://github.com/example/multicmd/issues

## See Also

buildtool(1), deploy(1), config(5), multicmd-init(1), multicmd-build(1)

## History

Version 2.0.0 (2024) - Complete rewrite with subcommand support
Version 1.5.0 (2023) - Added deployment capabilities
Version 1.0.0 (2022) - Initial release

## Author

Test Author <test@example.com>
Contributors: Alice Developer, Bob Maintainer

## Copyright

Copyright (C) 2024 Test Organization

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction.

MIT License - See LICENSE file for full text.