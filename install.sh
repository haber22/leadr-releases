#!/usr/bin/env bash
set -e

# LEADR TUI installer
# Detects platform and installs the appropriate binary

VERSION="${LEADR_VERSION:-latest}"
INSTALL_DIR="${LEADR_INSTALL_DIR:-/usr/local/bin}"
REPO="LEADR-official/leadr-releases"

# Detect platform
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Darwin)
    case "$ARCH" in
      x86_64)
        PLATFORM="macos-x86_64"
        ;;
      arm64)
        PLATFORM="macos-aarch64"
        ;;
      *)
        echo "Unsupported macOS architecture: $ARCH"
        exit 1
        ;;
    esac
    BINARY_NAME="leadr"
    ;;
  Linux)
    case "$ARCH" in
      x86_64)
        PLATFORM="linux-x86_64"
        ;;
      *)
        echo "Unsupported Linux architecture: $ARCH"
        echo "Please download the binary manually from:"
        echo "https://github.com/$REPO/releases"
        exit 1
        ;;
    esac
    BINARY_NAME="leadr"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    echo "Windows is not supported by this installer."
    echo "Please download the leadr Windows .exe from:"
    echo "https://leadr.gg/windows"
    exit 1
    ;;
  *)
    echo "Unsupported operating system: $OS"
    exit 1
    ;;
esac

# Get latest version if not specified
if [ "$VERSION" = "latest" ]; then
  VERSION=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  if [ -z "$VERSION" ]; then
    echo "Failed to get latest version"
    exit 1
  fi
fi

echo "Installing leadr $VERSION for $PLATFORM..."

# Download binary
BINARY_URL="https://github.com/$REPO/releases/download/$VERSION/leadr-$VERSION-$PLATFORM"
TEMP_FILE="/tmp/leadr-$VERSION"

echo "Downloading from $BINARY_URL..."
curl -sL "$BINARY_URL" -o "$TEMP_FILE"

# Verify checksum
echo "Verifying checksum..."
CHECKSUMS_URL="https://github.com/$REPO/releases/download/$VERSION/checksums.txt"
EXPECTED_CHECKSUM=$(curl -sL "$CHECKSUMS_URL" | grep "leadr-$VERSION-$PLATFORM" | awk '{print $1}')

if [ -n "$EXPECTED_CHECKSUM" ]; then
  if command -v shasum &> /dev/null; then
    ACTUAL_CHECKSUM=$(shasum -a 256 "$TEMP_FILE" | awk '{print $1}')
  else
    ACTUAL_CHECKSUM=$(sha256sum "$TEMP_FILE" | awk '{print $1}')
  fi
  if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    echo "Checksum verification failed!"
    echo "Expected: $EXPECTED_CHECKSUM"
    echo "Got: $ACTUAL_CHECKSUM"
    rm "$TEMP_FILE"
    exit 1
  fi
  echo "Checksum verified"
else
  echo "Warning: Could not verify checksum"
fi

# Install binary
chmod +x "$TEMP_FILE"

# Try to install to $INSTALL_DIR, fall back to user directory if no permissions
if mv "$TEMP_FILE" "$INSTALL_DIR/leadr" 2>/dev/null; then
  echo "Successfully installed to $INSTALL_DIR/leadr"
else
  mkdir -p "$HOME/.local/bin"
  mv "$TEMP_FILE" "$HOME/.local/bin/leadr"
  echo "Successfully installed to $HOME/.local/bin/leadr"
  echo ""
  echo "Note: Make sure $HOME/.local/bin is in your PATH"
  echo "Add this to your shell profile:"
  echo '  export PATH="$HOME/.local/bin:$PATH"'
fi

echo ""
echo "leadr $VERSION installed successfully!"
echo "Run 'leadr' to start the TUI"
