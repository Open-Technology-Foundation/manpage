# testcmd

A simple test command for the manpage test suite.

## Synopsis

`testcmd [options] file`

## Description

This is a test command used to verify the manpage generation functionality.

## Options

- `-h, --help` - Show help message
- `-v, --verbose` - Enable verbose output
- `-f, --force` - Force operation

## Examples

```bash
testcmd myfile.txt
testcmd -v data.json
testcmd --force --verbose report.pdf
```

## Environment

- `TESTCMD_HOME` - Home directory for testcmd

## Exit Status

- 0 - Success
- 1 - General error
- 2 - Invalid arguments

## Author

Test Suite

## Copyright

MIT License