#!/usr/bin/env sh

set -eu

# ------------------------
# 1. Define default values
# ------------------------
GH_USER="{{GH_USER}}"
PROJECT="{{PROJECT}}"
ENTRYPOINT="{{ENTRYPOINT}}"

BIN_DIR="$HOME/.local/bin"
ENVS_DIR="$HOME/.local/envs"

# Either empty or set from user input:
VERSION=""
NAME=""

usage() {
  echo "Usage: $0 [options]"
  echo "  [--gh-user GH_USER]         GitHub user (default: $GH_USER)"
  echo "  [--project PROJECT]         Project name (default: $PROJECT)"
  echo "  [--entrypoint ENTRYPOINT]   Program to extract from the environment (default: $ENTRYPOINT)"
  echo "  [--name NAME]               Name of executable (default: $ENTRYPOINT)"
  echo "  [--version VERSION]         Version to install (default: latest from GitHub)"
  echo "  [--bin-dir BIN_DIR]         Directory to place symlink (default: $BIN_DIR)"
  echo "  [--envs-dir ENVS_DIR]       Directory where environments are stored (default: $ENVS_DIR)"
  echo "  [--help]                    Show this usage message"
  exit 1
}

# --------------------------------
# 2. Parse CLI arguments if given
# --------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --gh-user)
      GH_USER="$2"
      shift 2
      ;;
    --project)
      PROJECT="$2"
      shift 2
      ;;
    --entrypoint)
      ENTRYPOINT="$2"
      shift 2
      ;;
    --name)
      NAME="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --bin-dir)
      BIN_DIR="$2"
      shift 2
      ;;
    --envs-dir)
      ENVS_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# -----------------------
# 3. Rest of the script
# -----------------------

if [ -z "$NAME" ]; then
  NAME="$ENTRYPOINT"
fi

BIN="$BIN_DIR/$NAME"
ENV_DIR="$ENVS_DIR/$PROJECT"

# check if the bin exists and error if it does
if [ -L "$BIN" ] || [ -e "$BIN" ]; then
  echo "Error: $BIN already exists. Please remove it before running this script."
  exit 1
fi

mkdir -p "$BIN_DIR"
mkdir -p "$ENV_DIR"

get_version_from_github() {
  ver=$(wget -qO - "https://api.github.com/repos/${GH_USER}/${PROJECT}/releases/latest" \
    | grep '"tag_name":' \
    | sed -E 's/.*"([^"]+)".*/\1/')
  echo "$ver"
}

# If user didn't provide --version, ask GitHub for the latest
if [ -z "$VERSION" ]; then
  VERSION=$(get_version_from_github)
fi

if [ -z "$VERSION" ]; then
  echo "Failed to get the latest version from GitHub."
  exit 1
fi

echo "Version: $VERSION"

get_operating_system() {
  case "$(uname -s)" in
    Darwin)
      echo "osx"
      ;;
    Linux)
      echo "linux"
      ;;
    *)
      echo "Unsupported OS"
      exit 1
      ;;
  esac
}

OS=$(get_operating_system)
if [ -z "$OS" ]; then
  echo "Failed to determine the operating system."
  exit 1
fi
echo "Operating system: $OS"

get_architecture() {
  case "$(uname -m)" in
    x86_64)
      echo "64"
      ;;
    arm64)
      echo "arm64"
      ;;
    *)
      echo "Unsupported architecture"
      exit 1
      ;;
  esac
}

ARCH=$(get_architecture)
if [ -z "$ARCH" ]; then
  echo "Failed to determine the architecture."
  exit 1
fi
echo "Architecture: $ARCH"

download_installer() {
  file=$1
  url=$2
  wget --output-document="$file" "$url"
}

URL="https://github.com/${GH_USER}/${PROJECT}/releases/download/${VERSION}/${PROJECT}-${VERSION}-${OS}-${ARCH}.sh"
FILE="${ENV_DIR}/${PROJECT}-${VERSION}-${OS}-${ARCH}.sh"

if [ -f "$FILE" ]; then
  echo "Installer already downloaded: $FILE"
else
  echo "Installer not found, downloading..."
  download_installer "$FILE" "$URL"
fi

if [ ! -f "$FILE" ]; then
  echo "Failed to download the installer."
  exit 1
fi

echo "Running installer"
chmod +x "$FILE"
"$FILE" --output-directory "$ENV_DIR"

# add the entrypoint to activate.sh
cat "${ENV_DIR}/activate.sh" > "${ENV_DIR}/${NAME}"
echo "$ENTRYPOINT \$@" >> "${ENV_DIR}/${NAME}"
chmod +x "${ENV_DIR}/${NAME}"

echo "Creating symlink to "${ENV_DIR}/${NAME}" in $BIN_DIR"
ln -s "${ENV_DIR}/${NAME}" "$BIN"

# check BIN_DIR is in PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
  echo "Warning: $BIN_DIR is not in your PATH. Please add it to your PATH."
  echo "You can do this by adding the following line to your ~/.bashrc or ~/.zshrc:"
  echo "export PATH=\$PATH:$BIN_DIR"
fi

echo "Installation complete!"
