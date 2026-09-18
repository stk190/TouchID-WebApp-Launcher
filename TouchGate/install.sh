#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/Applications"

APP_NAME=""
TARGET_PATH=""
LOCKED_NAME=""
BUNDLE_ID=""

print_header() {
  echo "TouchID WebApp Launcher"
  echo
  echo "This creates one locked launcher for one Safari web app."
  echo "The original web app is not modified."
  echo
}

ask_for_app_name() {
  read -r -p "Which web app do you want to lock? Example: WhatsApp: " APP_NAME

  if [[ -z "$APP_NAME" ]]; then
    echo "App name is required." >&2
    exit 1
  fi
}

expand_path() {
  local path="$1"
  if [[ "$path" == "~/"* ]]; then
    printf '%s/%s\n' "$HOME" "${path#~/}"
  else
    printf '%s\n' "$path"
  fi
}

slugify() {
  printf '%s\n' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9' '-' \
    | sed 's/^-//; s/-$//'
}

find_target_app() {
  TARGET_PATH="$HOME/Applications/$APP_NAME.app"

  if [[ ! -d "$TARGET_PATH" ]]; then
    echo
    echo "I could not find:"
    echo "$TARGET_PATH"
    echo
    read -r -p "Paste the full path to the web app: " TARGET_PATH
    TARGET_PATH="$(expand_path "$TARGET_PATH")"
  fi

  if [[ ! -d "$TARGET_PATH" ]]; then
    echo "Target app not found: $TARGET_PATH" >&2
    exit 1
  fi
}

prepare_summary() {
  local slug

  slug="$(slugify "$APP_NAME")"
  LOCKED_NAME="Locked $APP_NAME"
  BUNDLE_ID="local.touchid.webapp-launcher.$slug"
}

confirm_conditions() {
  echo
  echo "Please review:"
  echo
  echo "Original web app:  $TARGET_PATH"
  echo "Locked launcher:   $INSTALL_DIR/$LOCKED_NAME.app"
  echo "Bundle ID:         $BUNDLE_ID"
  echo
  echo "Conditions:"
  echo "1. This creates a separate locked launcher app."
  echo "2. It does not modify the original Safari web app."
  echo "3. It only protects opening through the locked launcher."
  echo "4. It does not lock an app that is already open."
  echo "5. It does not stop someone from opening the original app directly."
  echo

  read -r -p "Type I AGREE to build and install: " consent

  if [[ "$consent" != "I AGREE" ]]; then
    echo "Cancelled. Nothing was changed."
    exit 0
  fi
}

build_launcher() {
  "$ROOT/scripts/build.sh" \
    --app-name "$APP_NAME" \
    --target-path "$TARGET_PATH"
}

install_launcher() {
  local built_app="$1"
  local installed_app="$INSTALL_DIR/$(basename "$built_app")"

  mkdir -p "$INSTALL_DIR"

  if [[ -e "$installed_app" ]]; then
    echo
    echo "A locked launcher already exists:"
    echo "$installed_app"
    echo
    read -r -p "Replace it? Type REPLACE: " replace

    if [[ "$replace" != "REPLACE" ]]; then
      echo "Cancelled. Existing launcher was not changed."
      exit 0
    fi

    rm -rf "$installed_app"
  fi

  cp -R "$built_app" "$installed_app"

  echo
  echo "Done."
  echo "Installed:"
  echo "$installed_app"
  echo
  echo "Next: drag '$LOCKED_NAME' from ~/Applications into your Dock."
}

main() {
  local built_app

  print_header
  ask_for_app_name
  find_target_app
  prepare_summary
  confirm_conditions
  built_app="$(build_launcher)"
  install_launcher "$built_app"
}

main "$@"
