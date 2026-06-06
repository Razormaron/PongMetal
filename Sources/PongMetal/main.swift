import AppKit

// Standard SPM entry point for a headful macOS app.
let app      = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
