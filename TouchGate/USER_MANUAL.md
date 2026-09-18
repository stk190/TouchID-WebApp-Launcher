# User Manual

## Requirements

- macOS 14 or newer
- Touch ID set up
- Apple Command Line Tools installed
- A Safari web app already saved in `~/Applications`

## Install a Locked Launcher

Open Terminal:

```bash
cd ~/Documents/projects/TouchID-WebApp-Launcher/TouchGate
./install.sh
```

The script will ask:

- Which web app you want to lock.

Example:

```text
WhatsApp
```

The installer first checks:

```text
~/Applications/WhatsApp.app
```

If the app is somewhere else, it asks you to paste the full path.

## Consent Step

Before installing anything, the script shows:

- The original web app path.
- The new locked launcher path.
- The bundle identifier.
- The security limits of this approach.

Type this exact phrase only if the summary looks correct:

```text
I AGREE
```

## After Installation

The locked app will be created in:

```text
~/Applications
```

For example:

```text
~/Applications/Locked WhatsApp.app
```

Drag the locked launcher into your Dock. Remove the original web app icon from the Dock if you want the Dock workflow to require Touch ID.

## Security Limits

This protects opening the app through the locked launcher. It does not:

- Lock apps that are already open.
- Stop someone from opening the original app directly.
- Stop someone from visiting the same website in a browser.
