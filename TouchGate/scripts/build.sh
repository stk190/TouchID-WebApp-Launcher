#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT/Sources/TouchGateLauncher.swift"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
APP_DIR="$BUILD_DIR/apps"
EXECUTABLE="$BUILD_DIR/TouchGateLauncher"

APP_NAME=""
TARGET_PATH=""

usage() {
  cat <<'USAGE'
Usage: scripts/build.sh --app-name NAME --target-path PATH

Build one locked TouchGate launcher into build/apps.

This is the developer/helper script. Most users should run ./install.sh.
USAGE
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

plist_add() {
  local plist="$1"
  local key="$2"
  local type="$3"
  local value="$4"

  /usr/libexec/PlistBuddy -c "Add :$key $type $value" "$plist"
}

read_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --app-name)
        APP_NAME="${2:?missing value after --app-name}"
        shift 2
        ;;
      --target-path)
        TARGET_PATH="${2:?missing value after --target-path}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        printf 'Unknown option: %s\n' "$1" >&2
        usage >&2
        exit 64
        ;;
    esac
  done

  if [[ -z "$APP_NAME" || -z "$TARGET_PATH" ]]; then
    usage >&2
    exit 64
  fi
}

validate_inputs() {
  TARGET_PATH="$(expand_path "$TARGET_PATH")"
  ICON_PATH="$TARGET_PATH/Contents/Resources/ApplicationIcon.icns"

  if [[ ! -f "$SOURCE" ]]; then
    printf 'Launcher source not found: %s\n' "$SOURCE" >&2
    exit 66
  fi

  if [[ ! -d "$TARGET_PATH" ]]; then
    printf 'Target app not found: %s\n' "$TARGET_PATH" >&2
    exit 66
  fi

  if [[ ! -f "$ICON_PATH" ]]; then
    printf 'Icon not found: %s\n' "$ICON_PATH" >&2
    exit 66
  fi
}

prepare_names() {
  local slug

  slug="$(slugify "$APP_NAME")"
  LOCKED_NAME="Locked $APP_NAME"
  BUNDLE_ID="local.touchid.webapp-launcher.$slug"
  APP_PATH="$APP_DIR/$LOCKED_NAME.app"
}

compile_launcher() {
  rm -rf "$BUILD_DIR"
  mkdir -p "$APP_DIR"

  swiftc "$SOURCE" \
    -framework AppKit \
    -framework LocalAuthentication \
    -o "$EXECUTABLE"
}

write_info_plist() {
  local plist="$1"

  /usr/libexec/PlistBuddy -c "Clear dict" "$plist" >/dev/null 2>&1 || true
  plist_add "$plist" "CFBundleDevelopmentRegion" "string" "en"
  plist_add "$plist" "CFBundleDisplayName" "string" "$LOCKED_NAME"
  plist_add "$plist" "CFBundleExecutable" "string" "TouchGateLauncher"
  plist_add "$plist" "CFBundleIconFile" "string" "ApplicationIcon"
  plist_add "$plist" "CFBundleIdentifier" "string" "$BUNDLE_ID"
  plist_add "$plist" "CFBundleInfoDictionaryVersion" "string" "6.0"
  plist_add "$plist" "CFBundleName" "string" "$LOCKED_NAME"
  plist_add "$plist" "CFBundlePackageType" "string" "APPL"
  plist_add "$plist" "CFBundleShortVersionString" "string" "1.0"
  plist_add "$plist" "CFBundleVersion" "string" "1"
  plist_add "$plist" "LSMinimumSystemVersion" "string" "14.0"
  plist_add "$plist" "TargetApplicationName" "string" "$APP_NAME"
  plist_add "$plist" "TargetApplicationPath" "string" "$TARGET_PATH"
}

build_app_bundle() {
  local plist="$APP_PATH/Contents/Info.plist"

  mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
  cp "$EXECUTABLE" "$APP_PATH/Contents/MacOS/TouchGateLauncher"
  cp "$ICON_PATH" "$APP_PATH/Contents/Resources/ApplicationIcon.icns"

  write_info_plist "$plist"
  codesign --force --sign - "$APP_PATH" >/dev/null
}

main() {
  read_args "$@"
  validate_inputs
  prepare_names
  compile_launcher
  build_app_bundle

  printf '%s\n' "$APP_PATH"
}

main "$@"
