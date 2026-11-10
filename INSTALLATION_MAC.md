# 🍏 Installing and Testing KobeanQAUtils on macOS Without an Apple Developer Account

You **do NOT** need to pay $99/year for an Apple Developer Account to build, install, and test **KobeanQAUtils** natively on your MacBook Pro.

Apple allows full local testing and execution on macOS through:
1. **Ad-Hoc Code Signing (`codesign -s -`)** — "Sign to Run Locally", recognized natively by macOS kernel/AMFI.
2. **Free Personal Apple ID Team** — Provisioning with your personal Apple ID (`@icloud.com`, `@gmail.com`) in Xcode.
3. **Quarantine Stripping (`xattr -cr`)** — Clearing the browser/download quarantine attribute so Gatekeeper allows immediate launch without security blocks.

KobeanQAUtils offers **two macOS desktop options**:
- **Native macOS App (SwiftUI + WebKit)** *(Recommended)*: ~45 MB bundle, native macOS menu bar, native window styling, Safari Web Inspector support, instant launch, and very low memory usage (~30MB vs 300MB+ in Electron).
- **Electron Desktop App**: ~616 MB bundle, Chromium + Node.js runtime with CORS bypass.

---

## ⚡ Quick Comparison

| Feature | 🍏 Native macOS App (SwiftUI) | ⚡ Desktop App (Electron) |
| :--- | :--- | :--- |
| **Technology** | Swift 6 / SwiftUI + WebKit `WKWebView` | Node.js + Chromium + Electron 40 |
| **App Bundle Size** | **~45 MB** (Self-contained) | ~616 MB |
| **Memory Footprint** | **~30–50 MB RAM** | ~300–450 MB RAM |
| **Launch Speed** | Instant (< 0.2s) | 1–2s |
| **Xcode Integration** | Yes (`macos/KobeanQAUtils.xcodeproj`) | No |
| **Live Dev Reload** | Yes (`http://localhost:5173` toggle) | Yes (`npm run electron:dev`) |
| **Apple Dev Account Needed?** | **No** (Ad-Hoc / Personal Team) | **No** (Ad-Hoc / Local Cert) |
| **Install Location** | `/Applications/KobeanQAUtils.app` | `/Applications/KobeanQAUtils.app` |

---

## 🚀 Option 1: Native macOS App (Recommended)

### Method A: One-Command Automated Build & Install

Run one command in your terminal from the repository root:

```bash
npm run mac:install
# or: make mac-install
```

What this script (`scripts/install-native-mac.sh`) automatically does:
1. Builds the production React/TypeScript web bundle (`npm run build`).
2. Generates the Xcode project using `xcodegen`.
3. Compiles the native Swift/SwiftUI application for Release (`arm64` Apple Silicon).
4. Embeds the web assets directly inside `Contents/Resources/dist` for a 100% self-contained app bundle.
5. Code-signs the bundle with Ad-Hoc ("Sign to Run Locally") and sandbox entitlements.
6. Copies the app into `/Applications/KobeanQAUtils.app`.
7. Strips macOS quarantine (`xattr -cr`) so Gatekeeper doesn't show any warning dialogs.
8. Registers with macOS LaunchServices so it appears in Spotlight and Launchpad.

Launch it immediately:
```bash
open /Applications/KobeanQAUtils.app
# Or pass --launch flag:
./scripts/install-native-mac.sh --launch
```

---

### Method B: Developing & Running in Xcode (For iOS/macOS Developers)

As an iOS/macOS developer, you can open and run the project directly in Xcode:

1. **Generate and open the Xcode project**:
   ```bash
   npm run mac:native:generate
   open macos/KobeanQAUtils.xcodeproj
   ```

2. **Select your Free Apple ID / Personal Team**:
   - In Xcode's project navigator, select the top-level **KobeanQAUtils** project.
   - Select the **KobeanQAUtils** target under *TARGETS*.
   - Click the **Signing & Capabilities** tab.
   - Set **Signing Certificate** to *Sign to Run Locally* (or select your personal free Apple ID in the *Team* dropdown).

3. **Hit Run (`⌘R`)**:
   - Xcode will compile and launch KobeanQAUtils natively with Xcode debugger, memory graph, and Instruments attached.

---

### Method C: Dual Mode — Live Dev Server vs Bundled Production

The native macOS app features an **Environment Switcher** in the toolbar and navigation menu:
- **Bundled App (`kobean://app/index.html`)**: Runs the production built bundle offline.
- **Live Dev Server (`http://localhost:5173`)**: Connects directly to Vite's local dev server for live hot-reloading!

To use Live Dev Server mode:
1. Start the Vite dev server in terminal:
   ```bash
   npm run dev
   ```
2. In the native macOS app:
   - Click the segmented control in the top toolbar to switch to **Live Dev Server (5173)**, OR
   - Press **`⇧⌘D`** (or go to menu **Navigation** → **Toggle Dev / Bundled Mode**).
3. The app will immediately load `http://localhost:5173` with instant hot-reloading as you edit frontend code.
4. Right click anywhere in the window and choose **Inspect Element** to open Safari Web Inspector / DevTools!

---

## ⚡ Option 2: Electron Desktop App

If you want to test the Electron desktop packaging locally without an Apple Developer account:

### One-Command Electron Install

```bash
npm run mac:electron:install
# or: make mac-electron-install
```

What this script (`scripts/install-electron-mac.sh`) automatically does:
1. Builds the web bundle with relative paths (`ELECTRON=true npm run build`).
2. Packages the unpacked Electron app using `electron-builder --mac --dir` with `identity: null` (preventing Keychain prompt stalls).
3. Re-signs all frameworks (`Electron Framework`, helpers, dylibs) with deep Ad-Hoc code signing and `entitlements.mac.plist`.
4. Installs into `/Applications/KobeanQAUtils.app`.
5. Clears Gatekeeper quarantine (`xattr -cr`).
6. Verifies the code signature with `codesign --verify --deep --strict`.

Launch it:
```bash
open /Applications/KobeanQAUtils.app
```

---

## 🛡️ Understanding macOS Gatekeeper & Quarantine

When an application is built or downloaded outside the Mac App Store without a paid $99/year Apple Developer ID certificate and Apple Notarization ticket, macOS applies Gatekeeper protections:

### Why Gatekeeper Normally Blocks Unsigned Apps
1. When you download a `.zip` or `.dmg`, macOS attaches the `com.apple.quarantine` extended attribute.
2. When launched, macOS Gatekeeper sees the quarantine attribute, notes the absence of an Apple Notarization ticket, and blocks the app: *"KobeanQAUtils is damaged and can't be opened"* or *"macOS cannot verify the developer"*.

### How Our Local Install Scripts Bypass This Legally
1. **Ad-Hoc Signing (`codesign -s -`)**: Signs the Mach-O binary and hashes every resource file into `_CodeSignature/CodeResources`. This satisfies macOS kernel / AMFI verification that the binary hasn't been tampered with.
2. **Quarantine Removal (`xattr -cr /Applications/KobeanQAUtils.app`)**: Strips the quarantine attribute. Since the app is built locally by you on your own Mac, it is a trusted local build. Gatekeeper allows it to launch immediately.

### Manual Fix (If You Ever Move or Download an App Manually)
If macOS ever prompts *"App is damaged and can't be opened"*:
```bash
xattr -cr /Applications/KobeanQAUtils.app
codesign --force --deep --sign - /Applications/KobeanQAUtils.app
```
Alternatively:
- Open **System Settings** > **Privacy & Security** > scroll down to Security > click **"Open Anyway"**.
- Or in Finder: **Right-click (Control-click)** on `KobeanQAUtils.app` > select **Open** > click **Open** on the confirmation dialog.

---

## 📋 Summary of Available Commands

| Command | Action |
| :--- | :--- |
| `npm run mac:install` | **Build & install native macOS app to `/Applications`** *(Recommended)* |
| `npm run mac:native:generate` | Generate `macos/KobeanQAUtils.xcodeproj` using XcodeGen |
| `npm run mac:native:build` | Compile native Swift app via Swift PM |
| `npm run mac:native:install` | Build, ad-hoc sign, and install native SwiftUI app |
| `npm run mac:electron:install` | Build, ad-hoc sign, and install Electron desktop app |
| `open macos/KobeanQAUtils.xcodeproj` | Open native app in Xcode for live debugging |
