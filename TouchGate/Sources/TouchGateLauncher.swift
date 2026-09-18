import AppKit
import Foundation
import LocalAuthentication

// The generated app bundle stores its target app in Info.plist. This keeps the
// Swift executable reusable for any Safari web app the installer creates.
let bundle = Bundle.main

guard
    let appName = bundle.object(forInfoDictionaryKey: "TargetApplicationName") as? String,
    let targetPath = bundle.object(forInfoDictionaryKey: "TargetApplicationPath") as? String
else {
    NSLog("Missing target application metadata.")
    exit(2)
}

// Ask macOS for biometric owner authentication. Fingerprint data stays inside
// the system; TouchGate only receives success or failure.
let context = LAContext()
context.localizedCancelTitle = "Cancel"
context.localizedFallbackTitle = ""

var authError: NSError?
guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
    let message = authError?.localizedDescription ?? "Touch ID is not available."
    let alert = NSAlert()
    alert.messageText = "Cannot unlock \(appName)"
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.runModal()
    exit(1)
}

let reason = "Use Touch ID to open \(appName)."
let semaphore = DispatchSemaphore(value: 0)
var authenticated = false

context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
    if success {
        authenticated = true
    } else if let error {
        NSLog("Authentication cancelled or failed: \(error.localizedDescription)")
    }
    semaphore.signal()
}

_ = semaphore.wait(timeout: .now() + 60)

guard authenticated else {
    exit(1)
}

// Authentication succeeded, so open the original Safari web app. The target app
// bundle is not edited or wrapped; it is only launched.
let targetURL = URL(fileURLWithPath: targetPath)
let configuration = NSWorkspace.OpenConfiguration()
configuration.activates = true

NSWorkspace.shared.openApplication(at: targetURL, configuration: configuration) { _, error in
    if let error {
        let alert = NSAlert()
        alert.messageText = "Could not open \(appName)"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.runModal()
        exit(1)
    }
    exit(0)
}

RunLoop.main.run()
