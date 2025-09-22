#!/usr/bin/env bash
# Installation script for manpage utility
# Installs manpage script, bash completion, and man page
set -euo pipefail

# Script metadata
VERSION='1.0.0'
REPO_URL='https://raw.githubusercontent.com/Open-Technology-Foundation/manpage/main'
INSTALL_DIR='/usr/local/bin'
COMPLETION_DIR='/etc/bash_completion.d'
MAN_DIR='/usr/local/share/man/man1'
TEMP_DIR=$(mktemp -d)
readonly -- VERSION REPO_URL TEMP_DIR

# Colors for output
if [[ -t 1 && -t 2 ]]; then
  declare -- RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[0;33m' CYAN=$'\033[0;36m' NC=$'\033[0m' BOLD=$'\033[1m'
else
  declare -- RED='' GREEN='' YELLOW='' CYAN='' NC='' BOLD=''
fi
readonly -- RED GREEN YELLOW CYAN NC BOLD

# Cleanup on exit
cleanup() {
  [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Message functions
error() { echo "${RED}✗${NC} $*" >&2; }
warn() { echo "${YELLOW}⚡${NC} $*" >&2; }
info() { echo "${CYAN}◉${NC} $*" >&2; }
success() { echo "${GREEN}✓${NC} $*" >&2; }

# Check if running as root
is_root() {
  [[ $EUID -eq 0 ]]
}

# Detect download tool
get_downloader() {
  if command -v curl >/dev/null 2>&1; then
    echo "curl -sSL"
  elif command -v wget >/dev/null 2>&1; then
    echo "wget -qO-"
  else
    error "Neither curl nor wget found. Please install one."
    exit 1
  fi
}

# Download file from GitHub
download_file() {
  local -- url="$1" dest="$2"
  local -- downloader
  downloader=$(get_downloader)

  info "Downloading $(basename "$dest")..."
  if $downloader "$url" > "$dest"; then
    return 0
  else
    error "Failed to download: $url"
    return 1
  fi
}

# Check for required commands
check_dependencies() {
  local -a missing=()

  # Check for required commands
  for cmd in bash grep install; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing required dependencies: ${missing[*]}"
    error "Please install them and try again."
    exit 1
  fi
}

# Determine installation mode
determine_install_mode() {
  if [[ "${1:-}" == "--user" ]]; then
    INSTALL_DIR="$HOME/.local/bin"
    COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
    MAN_DIR="$HOME/.local/share/man/man1"
    info "User installation mode selected"
  elif is_root; then
    info "System-wide installation mode (running as root)"
  else
    warn "Not running as root. Use 'sudo' for system-wide installation."
    warn "Or use '--user' flag for user installation."
    echo ""
    echo "Installation command examples:"
    echo "  System-wide: curl -sSL $REPO_URL/install.sh | sudo bash"
    echo "  User local:  curl -sSL $REPO_URL/install.sh | bash -s -- --user"
    exit 1
  fi
}

# Install manpage script
install_manpage_script() {
  local -- script_path="$TEMP_DIR/manpage"

  # Download the script
  if ! download_file "$REPO_URL/manpage" "$script_path"; then
    return 1
  fi

  # Make executable
  chmod +x "$script_path"

  # Create install directory if needed
  if [[ ! -d "$INSTALL_DIR" ]]; then
    info "Creating directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
  fi

  # Install the script
  info "Installing manpage to $INSTALL_DIR..."
  if install -m 755 "$script_path" "$INSTALL_DIR/"; then
    success "Installed manpage script"
  else
    error "Failed to install manpage script"
    return 1
  fi

  # Check if directory is in PATH
  if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    if [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
      warn "$INSTALL_DIR is not in your PATH"
      info "Add to ~/.bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
  fi
}

# Install bash completion
install_bash_completion() {
  local -- completion_path="$TEMP_DIR/.bash_completion"

  # Download completion file
  if ! download_file "$REPO_URL/.bash_completion" "$completion_path"; then
    warn "Could not download bash completion file (optional)"
    return 0
  fi

  # Create completion directory if needed
  if [[ ! -d "$COMPLETION_DIR" ]]; then
    info "Creating directory: $COMPLETION_DIR"
    mkdir -p "$COMPLETION_DIR"
  fi

  # Install completion
  info "Installing bash completion to $COMPLETION_DIR..."
  if [[ "$COMPLETION_DIR" == "/etc/bash_completion.d" ]]; then
    # System-wide installation
    if install -m 644 "$completion_path" "$COMPLETION_DIR/manpage"; then
      success "Installed bash completion"
    else
      warn "Failed to install bash completion (optional)"
    fi
  else
    # User installation
    if install -m 644 "$completion_path" "$COMPLETION_DIR/manpage"; then
      success "Installed bash completion"
      info "Source it: source $COMPLETION_DIR/manpage"
    else
      warn "Failed to install bash completion (optional)"
    fi
  fi
}

# Install man page
install_man_page() {
  local -- readme_path="$TEMP_DIR/README.md"
  local -- manpage_file="$TEMP_DIR/manpage.1"

  # Check if manpage.1 already exists in repo
  info "Downloading man page..."
  if download_file "$REPO_URL/manpage.1" "$manpage_file" 2>/dev/null; then
    info "Using pre-generated man page"
  else
    # Try to generate it if claude is available
    if command -v claude >/dev/null 2>&1; then
      info "Generating man page using claude..."

      # Download README for generation
      if ! download_file "$REPO_URL/README.md" "$readme_path"; then
        warn "Could not download README.md for man page generation"
        return 0
      fi

      # Try to generate using the installed script
      if [[ -x "$INSTALL_DIR/manpage" ]]; then
        if "$INSTALL_DIR/manpage" generate manpage "$readme_path" 2>/dev/null; then
          manpage_file="$TEMP_DIR/manpage.1"
          info "Generated man page"
        else
          warn "Could not generate man page (optional)"
          return 0
        fi
      fi
    else
      warn "Man page not found and claude not available to generate it"
      return 0
    fi
  fi

  # Create man directory if needed
  if [[ ! -d "$MAN_DIR" ]]; then
    info "Creating directory: $MAN_DIR"
    mkdir -p "$MAN_DIR"
  fi

  # Install the man page
  info "Installing man page to $MAN_DIR..."
  if install -m 644 "$manpage_file" "$MAN_DIR/manpage.1"; then
    success "Installed man page"

    # Update man database
    if is_root; then
      if command -v mandb >/dev/null 2>&1; then
        info "Updating man database..."
        mandb >/dev/null 2>&1 || true
      elif command -v makewhatis >/dev/null 2>&1; then
        info "Updating man database..."
        makewhatis >/dev/null 2>&1 || true
      fi
    else
      # Check MANPATH for user installation
      if ! manpath 2>/dev/null | grep -q "$HOME/.local/share/man"; then
        warn "$HOME/.local/share/man may not be in MANPATH"
        info "Add to ~/.bashrc: export MANPATH=\"\$HOME/.local/share/man:\$MANPATH\""
      fi
    fi
  else
    warn "Failed to install man page (optional)"
  fi
}

# Uninstall function
uninstall() {
  info "Uninstalling manpage..."

  local -i removed=0

  # Remove script
  if [[ -f "$INSTALL_DIR/manpage" ]]; then
    if rm -f "$INSTALL_DIR/manpage"; then
      success "Removed $INSTALL_DIR/manpage"
      ((removed+=1))
    fi
  fi

  # Remove bash completion
  if [[ -f "$COMPLETION_DIR/manpage" ]]; then
    if rm -f "$COMPLETION_DIR/manpage"; then
      success "Removed $COMPLETION_DIR/manpage"
      ((removed+=1))
    fi
  fi

  # Remove man page
  if [[ -f "$MAN_DIR/manpage.1" ]]; then
    if rm -f "$MAN_DIR/manpage.1"; then
      success "Removed $MAN_DIR/manpage.1"
      ((removed+=1))

      # Update man database
      if is_root; then
        if command -v mandb >/dev/null 2>&1; then
          mandb >/dev/null 2>&1 || true
        elif command -v makewhatis >/dev/null 2>&1; then
          makewhatis >/dev/null 2>&1 || true
        fi
      fi
    fi
  fi

  if ((removed > 0)); then
    success "Uninstallation complete"
  else
    info "Nothing to uninstall"
  fi

  exit 0
}

# Main installation process
main() {
  echo "${BOLD}manpage installer v$VERSION${NC}"
  echo ""

  # Parse arguments
  case "${1:-}" in
    --uninstall)
      determine_install_mode "${2:-}"
      uninstall
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --user       Install for current user only"
      echo "  --uninstall  Remove manpage installation"
      echo "  --help       Show this help message"
      echo ""
      echo "Examples:"
      echo "  System-wide: curl -sSL $REPO_URL/install.sh | sudo bash"
      echo "  User local:  curl -sSL $REPO_URL/install.sh | bash -s -- --user"
      echo "  Uninstall:   curl -sSL $REPO_URL/install.sh | sudo bash -s -- --uninstall"
      exit 0
      ;;
  esac

  # Check dependencies
  check_dependencies

  # Determine installation mode
  determine_install_mode "$@"

  info "Starting installation..."
  echo ""

  # Install components
  install_manpage_script || exit 1
  install_bash_completion
  install_man_page

  echo ""
  success "${BOLD}Installation complete!${NC}"
  echo ""
  echo "To get started:"
  echo "  man manpage           # Read the manual"
  echo "  manpage --help        # Show help"
  echo "  manpage generate -i mycommand  # Generate and install a man page"
  echo ""

  if [[ ! "$PATH" =~ $INSTALL_DIR ]]; then
    warn "Don't forget to add $INSTALL_DIR to your PATH!"
  fi
}

# Run main function
main "$@"
#fin