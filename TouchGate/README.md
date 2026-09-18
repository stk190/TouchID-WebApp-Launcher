# TouchID WebApp Launcher

A small macOS project that creates locked launcher apps for Safari web apps.

When a locked launcher is opened, macOS asks for Touch ID. If authentication succeeds, the original Safari web app opens. If authentication fails or is cancelled, nothing opens.

## Why This Exists

Safari web apps can be placed in the Dock, but they do not have their own Touch ID lock. This project adds a lightweight launcher layer in front of apps like WhatsApp, Facebook, and Instagram.

## How It Works

1. A generated `.app` bundle is opened.
2. The Swift launcher reads the target app path from `Info.plist`.
3. macOS shows a Touch ID prompt through `LocalAuthentication`.
4. On success, the target Safari web app opens through `NSWorkspace`.

## Quick Start

Download or clone this project, open Terminal in the project folder, then run:

```bash
./install.sh
```

The installer asks for one required thing:

```text
Which web app do you want to lock?
```

For example:

```text
WhatsApp
```

The installer looks for the matching Safari web app in `~/Applications`. If it cannot find it, it asks you to paste the app path.

Before anything is installed, the installer shows a summary and asks you to type:

```text
I AGREE
```

After that, it creates and installs a locked launcher such as:

```text
~/Applications/Locked WhatsApp.app
```

## Important Limits

This is not a full app locker. It does not lock apps that are already open, and it does not stop someone from opening the original app directly.

## Documentation

See `USER_MANUAL.md` for setup and usage instructions.
