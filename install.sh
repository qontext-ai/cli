#!/bin/sh
set -eu

REPO="qontext-ai/cli"
BIN_NAME="qontext"
VERSION="${QONTEXT_VERSION:-latest}"

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
  linux)  DEFAULT_INSTALL_DIR="/usr/bin" ;;
  darwin) DEFAULT_INSTALL_DIR="/usr/local/bin" ;;
  *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac
INSTALL_DIR="${QONTEXT_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64)   ARCH=amd64 ;;
  aarch64|arm64)  ARCH=arm64 ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

if [ "$VERSION" = "latest" ]; then
  VERSION=$(curl -fsSL "https://raw.githubusercontent.com/${REPO}/main/VERSION" | tr -d '[:space:]')
  if [ -z "$VERSION" ]; then
    echo "Failed to resolve current version from ${REPO}/VERSION" >&2
    exit 1
  fi
fi

ARCHIVE="${BIN_NAME}_${VERSION}_${OS}_${ARCH}.tar.gz"
CHECKSUMS="SHA256SUMS-${VERSION}.txt"
BASE_URL="https://github.com/${REPO}/releases/download/${VERSION}"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT HUP TERM

echo "Downloading ${ARCHIVE}..."
curl -fsSL --proto '=https' --tlsv1.2 -o "$TMP/$ARCHIVE"   "${BASE_URL}/${ARCHIVE}"
curl -fsSL --proto '=https' --tlsv1.2 -o "$TMP/$CHECKSUMS" "${BASE_URL}/${CHECKSUMS}"

echo "Verifying checksum..."
EXPECTED=$(awk -v f="$ARCHIVE" '$2 == f { print $1 }' "$TMP/$CHECKSUMS")
if [ -z "$EXPECTED" ]; then
  echo "Checksum for ${ARCHIVE} not found in ${CHECKSUMS}" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL=$(sha256sum "$TMP/$ARCHIVE" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  ACTUAL=$(shasum -a 256 "$TMP/$ARCHIVE" | awk '{print $1}')
else
  echo "Neither sha256sum nor shasum is available" >&2
  exit 1
fi

if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "Checksum mismatch for ${ARCHIVE}" >&2
  echo "  expected: $EXPECTED" >&2
  echo "  actual:   $ACTUAL" >&2
  exit 1
fi

tar -xzf "$TMP/$ARCHIVE" -C "$TMP"
if [ ! -f "$TMP/$BIN_NAME" ]; then
  echo "Archive did not contain expected binary '${BIN_NAME}'" >&2
  exit 1
fi

SUDO=""
if [ ! -w "$INSTALL_DIR" ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "Cannot write to ${INSTALL_DIR} and sudo is not available" >&2
    exit 1
  fi
fi

echo "Installing to ${INSTALL_DIR}/${BIN_NAME}..."
$SUDO install -m 0755 "$TMP/$BIN_NAME" "${INSTALL_DIR}/${BIN_NAME}"

echo "Installed ${BIN_NAME} ${VERSION} to ${INSTALL_DIR}/${BIN_NAME}"
