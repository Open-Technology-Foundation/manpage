#!/usr/bin/env bash
# test_manpage.sh - Comprehensive test suite for manpage command
set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANPAGE_CMD="$SCRIPT_DIR/../manpage"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
TEMP_DIR="/tmp/manpage_test_$$"
VALIDATE_SCRIPT="$SCRIPT_DIR/validate_man.sh"

# Color output for test results
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[0;33m'
  NC=$'\033[0m'
else
  RED='' GREEN='' YELLOW='' NC=''
fi

# Test counters
declare -i PASSED=0 FAILED=0 SKIPPED=0

# Setup and teardown
setup() {
  mkdir -p "$TEMP_DIR"
  cd "$TEMP_DIR"
  # Copy fixtures to temp dir for isolation
  cp -r "$FIXTURES_DIR"/* "$TEMP_DIR/" 2>/dev/null || true
}

teardown() {
  cd /
  rm -rf "$TEMP_DIR"
}

# Test execution wrapper
run_test() {
  local test_name="$1"
  local test_desc="${2:-$test_name}"
  local output
  local exit_code

  printf "Testing %-50s " "$test_desc..."

  if declare -F "$test_name" >/dev/null; then
    # Run test in subshell to capture output and exit code
    set +e
    output=$($test_name 2>&1)
    exit_code=$?
    set -e

    if [[ $exit_code -eq 0 ]]; then
      echo "${GREEN}✓ PASS${NC}"
      ((PASSED+=1))
    else
      echo "${RED}✗ FAIL${NC}"
      if [[ -n "$output" ]]; then
        echo "  Error output:" >&2
        echo "$output" | sed 's/^/    /' >&2
      fi
      ((FAILED+=1))
    fi
  else
    echo "${YELLOW}⊘ SKIP${NC} (not implemented)"
    ((SKIPPED+=1))
  fi
}

# Utility function to check if running as root
is_root() {
  [[ $EUID -eq 0 ]]
}

# Mock claude command if not available
mock_claude() {
  if ! command -v claude >/dev/null 2>&1; then
    cat > "$TEMP_DIR/claude" <<'EOF'
#!/bin/bash
# Mock claude for testing
cat <<'MANPAGE'
.TH TEST 1 "December 2024" "1.0" "User Commands"
.SH NAME
test \- mock generated man page
.SH SYNOPSIS
.B test
[options]
.SH DESCRIPTION
This is a mock generated man page for testing.
MANPAGE
EOF
    chmod +x "$TEMP_DIR/claude"
    export PATH="$TEMP_DIR:$PATH"
  fi
}

# ==============================================================================
# Test Functions
# ==============================================================================

# Basic functionality tests
test_generate_simple() {
  cd "$TEMP_DIR/simple"
  "$MANPAGE_CMD" -q generate testcmd
  [[ -f testcmd.1 ]] || return 1
  grep -q '^\.TH' testcmd.1 || return 1
}

test_generate_with_path() {
  "$MANPAGE_CMD" -q generate simple/testcmd simple/README.md
  [[ -f simple/testcmd.1 ]] || return 1
}

test_generate_install_flag() {
  cd "$TEMP_DIR/simple"
  "$MANPAGE_CMD" -q generate -i testcmd
  [[ -f "$HOME/.local/share/man/man1/testcmd.1" ]] || return 1
}

test_install_user() {
  cd "$TEMP_DIR/simple"
  "$MANPAGE_CMD" -q generate testcmd
  "$MANPAGE_CMD" -q install testcmd
  [[ -f "$HOME/.local/share/man/man1/testcmd.1" ]] || return 1
}

test_install_root() {
  if ! is_root; then
    return 0  # Skip if not root
  fi
  cd "$TEMP_DIR/simple"
  "$MANPAGE_CMD" -q generate testcmd
  "$MANPAGE_CMD" -q install testcmd
  [[ -f "/usr/local/share/man/man1/testcmd.1" ]] || return 1
}

# Path resolution tests
test_relative_paths() {
  cd "$TEMP_DIR"
  "$MANPAGE_CMD" -q generate ./simple/testcmd
  [[ -f simple/testcmd.1 ]] || return 1
}

test_absolute_paths() {
  "$MANPAGE_CMD" -q generate "$TEMP_DIR/simple/testcmd"
  [[ -f "$TEMP_DIR/simple/testcmd.1" ]] || return 1
}

# Error handling tests
test_missing_readme() {
  cd "$TEMP_DIR/edge-cases/no-readme"
  ! "$MANPAGE_CMD" -q generate orphancmd 2>/dev/null
}

test_missing_command() {
  ! "$MANPAGE_CMD" -q generate nonexistent 2>/dev/null
}

test_invalid_command() {
  ! "$MANPAGE_CMD" -q generate /dev/null 2>/dev/null
}

test_malformed_readme() {
  cd "$TEMP_DIR/edge-cases/malformed"
  "$MANPAGE_CMD" -q generate badcmd
  [[ -f badcmd.1 ]] || return 1
  # Even malformed README should produce something
  grep -q '^\.TH' badcmd.1 || return 1
}

# Complex scenario tests
test_complex_readme() {
  cd "$TEMP_DIR/complex"
  "$MANPAGE_CMD" -q generate multicmd
  [[ -f multicmd.1 ]] || return 1

  # Validate it has multiple sections
  grep -q '^\.SH NAME' multicmd.1 || return 1
  grep -q '^\.SH SYNOPSIS' multicmd.1 || return 1
  grep -q '^\.SH DESCRIPTION' multicmd.1 || return 1
  grep -qE '^\.SH (GLOBAL )?OPTIONS' multicmd.1 || return 1
  grep -q '^\.SH EXAMPLES' multicmd.1 || return 1
  grep -q '^\.SH ENVIRONMENT' multicmd.1 || return 1
  grep -qE '^\.SH (EXIT STATUS|"EXIT STATUS")' multicmd.1 || return 1
  grep -q '^\.SH AUTHOR' multicmd.1 || return 1
}

# Edge case tests
test_spaces_in_path() {
  mkdir -p "$TEMP_DIR/path with spaces"
  cp "$TEMP_DIR/simple/testcmd" "$TEMP_DIR/path with spaces/cmd with spaces"
  cp "$TEMP_DIR/simple/README.md" "$TEMP_DIR/path with spaces/"
  cd "$TEMP_DIR"
  "$MANPAGE_CMD" -q generate "path with spaces/cmd with spaces"
  [[ -f "path with spaces/cmd with spaces.1" ]] || return 1
}

test_special_chars() {
  mkdir -p "$TEMP_DIR/special"
  cp "$TEMP_DIR/simple/testcmd" "$TEMP_DIR/special/test-cmd_2.0"
  cp "$TEMP_DIR/simple/README.md" "$TEMP_DIR/special/"
  "$MANPAGE_CMD" -q generate "$TEMP_DIR/special/test-cmd_2.0"
  [[ -f "$TEMP_DIR/special/test-cmd_2.0.1" ]] || return 1
}

test_empty_readme() {
  mkdir -p "$TEMP_DIR/empty"
  touch "$TEMP_DIR/empty/README.md"
  cp "$TEMP_DIR/simple/testcmd" "$TEMP_DIR/empty/emptycmd"
  "$MANPAGE_CMD" -q generate "$TEMP_DIR/empty/emptycmd"
  [[ -f "$TEMP_DIR/empty/emptycmd.1" ]] || return 1
}

# Validation tests
test_validate_simple() {
  cd "$TEMP_DIR/simple"
  "$MANPAGE_CMD" -q generate testcmd
  "$VALIDATE_SCRIPT" testcmd.1 || return 1
}

test_validate_complex() {
  cd "$TEMP_DIR/complex"
  "$MANPAGE_CMD" -q generate multicmd
  "$VALIDATE_SCRIPT" multicmd.1 || return 1
}

test_groff_syntax() {
  cd "$TEMP_DIR/simple"
  "$MANPAGE_CMD" -q generate testcmd
  # Test that groff can process the file without errors
  groff -t -man -Tascii testcmd.1 >/dev/null 2>&1 || return 1
}

test_man_rendering() {
  cd "$TEMP_DIR/simple"
  "$MANPAGE_CMD" -q generate testcmd
  # Test that man can render the file
  man -l testcmd.1 >/dev/null 2>&1 || return 1
}

# Options tests
test_verbose_mode() {
  cd "$TEMP_DIR/simple"
  output=$("$MANPAGE_CMD" -v generate testcmd 2>&1)
  [[ "$output" == *"Generating man page"* ]] || return 1
}

test_quiet_mode() {
  cd "$TEMP_DIR/simple"
  output=$("$MANPAGE_CMD" -q generate testcmd 2>&1)
  [[ -z "$output" ]] || return 1
}

test_help_option() {
  "$MANPAGE_CMD" --help | grep -q "Usage:" || return 1
}

test_version_option() {
  "$MANPAGE_CMD" --version | grep -qE "[0-9]+\.[0-9]+\.[0-9]+" || return 1
}

# ==============================================================================
# Main Test Runner
# ==============================================================================

main() {
  echo "=========================================="
  echo " manpage Test Suite"
  echo "=========================================="
  echo

  # Setup with trap at the beginning
  trap teardown EXIT
  setup

  # Mock claude if needed
  mock_claude

  # Run tests grouped by category
  echo "Basic Functionality Tests:"
  run_test test_generate_simple "Generate simple man page"
  run_test test_generate_with_path "Generate with explicit path"
  run_test test_generate_install_flag "Generate with install flag"
  run_test test_install_user "Install to user directory"
  if is_root; then
    run_test test_install_root "Install to system directory"
  else
    echo "Testing Install to system directory...              ${YELLOW}⊘ SKIP${NC} (requires root)"
    ((SKIPPED+=1))
  fi
  echo

  echo "Path Resolution Tests:"
  run_test test_relative_paths "Handle relative paths"
  run_test test_absolute_paths "Handle absolute paths"
  echo

  echo "Error Handling Tests:"
  run_test test_missing_readme "Missing README error"
  run_test test_missing_command "Missing command error"
  run_test test_invalid_command "Invalid command error"
  run_test test_malformed_readme "Malformed README handling"
  echo

  echo "Complex Scenario Tests:"
  run_test test_complex_readme "Complex README generation"
  echo

  echo "Edge Case Tests:"
  run_test test_spaces_in_path "Paths with spaces"
  run_test test_special_chars "Special characters in names"
  run_test test_empty_readme "Empty README file"
  echo

  echo "Validation Tests:"
  run_test test_validate_simple "Validate simple man page"
  run_test test_validate_complex "Validate complex man page"
  run_test test_groff_syntax "Groff syntax validation"
  run_test test_man_rendering "Man page rendering"
  echo

  echo "Option Tests:"
  run_test test_verbose_mode "Verbose mode"
  run_test test_quiet_mode "Quiet mode"
  run_test test_help_option "Help option"
  run_test test_version_option "Version option"
  echo

  # Summary
  echo "=========================================="
  echo " Test Results Summary"
  echo "=========================================="
  echo "  ${GREEN}Passed:${NC}  $PASSED"
  echo "  ${RED}Failed:${NC}  $FAILED"
  echo "  ${YELLOW}Skipped:${NC} $SKIPPED"
  echo "  Total:   $((PASSED + FAILED + SKIPPED))"
  echo "=========================================="

  if ((FAILED > 0)); then
    echo
    echo "${RED}TEST SUITE FAILED${NC}"
    exit 1
  else
    echo
    echo "${GREEN}TEST SUITE PASSED${NC}"
    exit 0
  fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi