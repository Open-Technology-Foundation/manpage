#!/usr/bin/env bash
# validate_man.sh - Validate generated man pages for correctness
set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERBOSE=${VERBOSE:-0}

# Color output
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[0;33m'
  CYAN=$'\033[0;36m'
  NC=$'\033[0m'
else
  RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi

# Validation counters
declare -i ERRORS=0 WARNINGS=0

# Logging functions
error() {
  echo "${RED}ERROR:${NC} $*" >&2
  ((ERRORS++))
}

warn() {
  echo "${YELLOW}WARNING:${NC} $*" >&2
  ((WARNINGS++))
}

info() {
  if ((VERBOSE)); then
    echo "${CYAN}INFO:${NC} $*"
  fi
}

success() {
  echo "${GREEN}✓${NC} $*"
}

# Check if required tools are available
check_requirements() {
  local -i missing=0

  if ! command -v groff >/dev/null 2>&1; then
    error "groff not found - required for man page validation"
    ((missing++))
  fi

  if ! command -v man >/dev/null 2>&1; then
    warn "man command not found - some tests will be skipped"
  fi

  return $missing
}

# Validate man page structure
validate_structure() {
  local manfile="$1"
  local basename="${manfile##*/}"

  info "Validating structure of $basename"

  # Check file exists and is readable
  if [[ ! -f "$manfile" ]]; then
    error "$manfile: File not found"
    return 1
  fi

  if [[ ! -r "$manfile" ]]; then
    error "$manfile: File not readable"
    return 1
  fi

  # Check for required .TH directive (title header)
  if ! grep -q '^\.TH' "$manfile"; then
    error "$basename: Missing .TH directive (title header)"
  else
    info "$basename: .TH directive found"
  fi

  # Check for NAME section (required)
  if ! grep -q '^\.SH NAME' "$manfile"; then
    error "$basename: Missing NAME section (required)"
  else
    info "$basename: NAME section found"
  fi

  # Check for SYNOPSIS section (strongly recommended)
  if ! grep -q '^\.SH SYNOPSIS' "$manfile"; then
    warn "$basename: Missing SYNOPSIS section (recommended)"
  else
    info "$basename: SYNOPSIS section found"
  fi

  # Check for DESCRIPTION section (strongly recommended)
  if ! grep -q '^\.SH DESCRIPTION' "$manfile"; then
    warn "$basename: Missing DESCRIPTION section (recommended)"
  else
    info "$basename: DESCRIPTION section found"
  fi

  # Check section ordering
  check_section_order "$manfile"
}

# Check that sections appear in standard order
check_section_order() {
  local manfile="$1"
  local basename="${manfile##*/}"

  # Standard section order (not all required)
  local -a standard_order=(
    "NAME"
    "SYNOPSIS"
    "DESCRIPTION"
    "OPTIONS"
    "ARGUMENTS"
    "EXAMPLES"
    "EXIT STATUS"
    "RETURN VALUE"
    "ERRORS"
    "ENVIRONMENT"
    "FILES"
    "VERSIONS"
    "CONFORMING TO"
    "NOTES"
    "BUGS"
    "SEE ALSO"
    "HISTORY"
    "AUTHORS?"
    "COPYRIGHT"
  )

  # Extract sections in order
  local -a found_sections=()
  while IFS= read -r section; do
    found_sections+=("$section")
  done < <(grep '^\.SH' "$manfile" | sed 's/^\.SH *//' | sed 's/"//g')

  info "$basename: Found sections: ${found_sections[*]}"

  # Check order
  local last_index=-1
  for section in "${found_sections[@]}"; do
    local current_index=-1
    for i in "${!standard_order[@]}"; do
      if [[ "${standard_order[$i]}" == "$section" ]] || [[ "$section" =~ ^${standard_order[$i]}$ ]]; then
        current_index=$i
        break
      fi
    done

    if ((current_index >= 0 && current_index < last_index)); then
      warn "$basename: Section '$section' appears out of standard order"
    fi

    if ((current_index >= 0)); then
      last_index=$current_index
    fi
  done
}

# Validate content consistency
validate_content() {
  local manfile="$1"
  local basename="${manfile##*/}"

  info "Validating content of $basename"

  # Extract command name from .TH line
  local th_name
  th_name=$(grep '^\.TH' "$manfile" | awk '{print $2}')

  if [[ -z "$th_name" ]]; then
    error "$basename: Cannot extract command name from .TH directive"
    return 1
  fi

  # Check that NAME section references the same command
  local name_line
  name_line=$(grep -A1 '^\.SH NAME' "$manfile" | tail -1)

  if [[ -n "$name_line" ]] && [[ ! "$name_line" =~ $th_name ]]; then
    # Case-insensitive check
    if [[ ! "${name_line,,}" =~ ${th_name,,} ]]; then
      warn "$basename: NAME section doesn't reference command '$th_name'"
    fi
  fi

  # Check for common formatting issues
  if grep -q '[[:space:]]$' "$manfile"; then
    warn "$basename: Contains trailing whitespace"
  fi

  # Check for very long lines (>80 chars is common limit)
  local long_lines
  long_lines=$(awk 'length > 80 { count++ } END { print count+0 }' "$manfile")
  if ((long_lines > 0)); then
    info "$basename: Contains $long_lines lines longer than 80 characters"
  fi
}

# Validate with groff
validate_groff() {
  local manfile="$1"
  local basename="${manfile##*/}"

  info "Validating $basename with groff"

  # Try to process with groff
  if output=$(groff -t -man -Tascii "$manfile" 2>&1 >/dev/null); then
    success "$basename: Valid groff syntax"
  else
    error "$basename: Groff validation failed"
    echo "$output" | sed 's/^/    /' >&2
    return 1
  fi

  # Check for groff warnings
  if output=$(groff -ww -t -man -Tascii "$manfile" 2>&1 >/dev/null); then
    if [[ -n "$output" ]]; then
      warn "$basename: Groff warnings:"
      echo "$output" | sed 's/^/    /' >&2
    fi
  fi
}

# Test rendering capability
test_rendering() {
  local manfile="$1"
  local basename="${manfile##*/}"

  info "Testing rendering of $basename"

  # Test ASCII rendering
  if man -l "$manfile" >/dev/null 2>&1; then
    success "$basename: Can be rendered with man"
  else
    warn "$basename: Failed to render with man command"
  fi

  # Test HTML conversion if groff supports it
  if groff -t -man -Thtml "$manfile" >/dev/null 2>&1; then
    info "$basename: HTML conversion supported"
  fi

  # Test UTF-8 rendering
  if groff -t -man -Tutf8 "$manfile" >/dev/null 2>&1; then
    info "$basename: UTF-8 rendering supported"
  fi
}

# Use Claude to validate if available
validate_with_claude() {
  local manfile="$1"
  local basename="${manfile##*/}"

  if ! command -v claude >/dev/null 2>&1; then
    info "Claude not available for semantic validation"
    return 0
  fi

  info "Validating $basename with Claude"

  local prompt="Review this man page for correctness and completeness. Check for:
1. Proper troff/man formatting
2. Clear and complete documentation
3. Consistent style
4. Any errors or issues

Respond with only: VALID, WARNING: <reason>, or ERROR: <reason>"

  local response
  if response=$(claude --print "$prompt" < "$manfile" 2>/dev/null); then
    case "$response" in
      VALID*)
        success "$basename: Claude validation passed"
        ;;
      WARNING:*)
        warn "$basename: Claude validation - ${response#WARNING: }"
        ;;
      ERROR:*)
        error "$basename: Claude validation - ${response#ERROR: }"
        ;;
      *)
        info "$basename: Claude validation response: $response"
        ;;
    esac
  fi
}

# Main validation function
validate_manpage() {
  local manfile="$1"

  echo "=========================================="
  echo " Validating: ${manfile##*/}"
  echo "=========================================="

  validate_structure "$manfile" || true
  validate_content "$manfile" || true
  validate_groff "$manfile" || true
  test_rendering "$manfile" || true
  validate_with_claude "$manfile" || true

  echo
}

# Print summary
print_summary() {
  echo "=========================================="
  echo " Validation Summary"
  echo "=========================================="

  if ((ERRORS == 0)); then
    echo "  ${GREEN}✓ No errors found${NC}"
  else
    echo "  ${RED}✗ $ERRORS error(s) found${NC}"
  fi

  if ((WARNINGS == 0)); then
    echo "  ${GREEN}✓ No warnings${NC}"
  else
    echo "  ${YELLOW}⚠ $WARNINGS warning(s)${NC}"
  fi

  echo "=========================================="

  if ((ERRORS > 0)); then
    return 1
  else
    return 0
  fi
}

# Main function
main() {
  # Check requirements
  if ! check_requirements; then
    echo "Missing required tools. Please install them and try again."
    exit 1
  fi

  # Parse arguments
  if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [-v] <manpage.1> [manpage2.1 ...]"
    echo "  -v    Verbose output"
    exit 1
  fi

  # Check for verbose flag
  if [[ "$1" == "-v" ]]; then
    VERBOSE=1
    shift
  fi

  # Validate each man page
  for manfile in "$@"; do
    validate_manpage "$manfile"
  done

  # Print summary and exit
  print_summary
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi