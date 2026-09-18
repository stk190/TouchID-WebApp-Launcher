#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$ROOT/Sources/TouchGateLauncher.swift"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/apps"
EXECUTABLE="$BUILD_DIR/TouchGateLauncher"
INSTALL_DIR="$HOME/Applications"

APP_NAME=""
TARGET_PATH=""
LOCKED_NAME=""
BUNDLE_ID=""
ICON_PATH=""

print_header() {
  echo "--- TouchGate - TouchID WebApp Launcher ---"
  echo
  echo "This tool creates a locked launcher for one Safari web app."
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

guess_target_path() {
  TARGET_PATH="$HOME/Applications/$APP_NAME.app"

  if [[ ! -d "$TARGET_PATH" ]]; then
    echo
    echo "I could not find:"
    echo "$TARGET_PATH"
    echo
    read -r -p "Paste the full path to the web app: " TARGET_PATH
  fi

  if [[ "$TARGET_PATH" == "~/"* ]]; then
    TARGET_PATH="$HOME/${TARGET_PATH#~/}"
  fi

  if [[ ! -d "$TARGET_PATH" ]]; then
    echo "Target app not found: $TARGET_PATH" >&2
    exit 1
  fi
}

prepare_names() {
  local slug

  slug="$(echo "$APP_NAME" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9' '-' \
    | sed 's/^-//; s/-$//')"

  LOCKED_NAME="Locked $APP_NAME"
  BUNDLE_ID="local.touchid.webapp-launcher.$slug"
  ICON_PATH="$TARGET_PATH/Contents/Resources/ApplicationIcon.icns"

  if [[ ! -f "$ICON_PATH" ]]; then
    echo "Icon not found: $ICON_PATH" >&2
    exit 1
  fi
}

confirm_conditions() {
  echo
  echo "--- Please review: ---"
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

  read -r -p "Type Y to build and install: " CONSENT

  if [[ "$CONSENT" != "Y" && "$CONSENT" != "y" ]]; then
    echo "Cancelled. Nothing was changed."
    exit 0
  fi
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
  /usr/libexec/PlistBuddy -c "Add :CFBundleDevelopmentRegion string en" "$plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $LOCKED_NAME" "$plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string TouchGateLauncher" "$plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string ApplicationIcon" "$plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleInfoDictionaryVersion string 6.0" "$plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleName string $LOCKED_NAME" "$plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0" "$plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1" "$plist"
  /usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 14.0" "$plist"
  /usr/libexec/PlistBuddy -c "Add :TargetApplicationName string $APP_NAME" "$plist"
  /usr/libexec/PlistBuddy -c "Add :TargetApplicationPath string $TARGET_PATH" "$plist"
}

build_app_bundle() {
  local app_path="$APP_DIR/$LOCKED_NAME.app"
  local plist="$app_path/Contents/Info.plist"

  mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"

  cp "$EXECUTABLE" "$app_path/Contents/MacOS/TouchGateLauncher"
  cp "$ICON_PATH" "$app_path/Contents/Resources/ApplicationIcon.icns"

  write_info_plist "$plist"

  codesign --force --sign - "$app_path" >/dev/null
}

install_app() {
  local built_app="$APP_DIR/$LOCKED_NAME.app"
  local installed_app="$INSTALL_DIR/$LOCKED_NAME.app"

  mkdir -p "$INSTALL_DIR"

  if [[ -e "$installed_app" ]]; then
    echo
    echo "A launcher already exists:"
    echo "$installed_app"
    echo
    read -r -p "Replace it? Type REPLACE: " REPLACE

    if [[ "$REPLACE" != "REPLACE" ]]; then
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
  print_header
  ask_for_app_name
  guess_target_path
  prepare_names
  confirm_conditions
  compile_launcher
  build_app_bundle
  install_app
}

main "$@"