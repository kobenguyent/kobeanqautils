# 🍏 Installing and Testing KobeanQAUtils on macOS Without an Apple Developer Account

You **do NOT** need to pay $99/year for an Apple Developer Account to build, install, and test **KobeanQAUtils** natively on your MacBook Pro.

Apple allows full local testing and execution on macOS through:
1. **Ad-Hoc Code Signing (`codesign -s -`)** — "Sign to Run Locally", recognized natively by macOS kernel/AMFI.
2. **Free Personal Apple ID Team** — Provisioning with your personal Apple ID (`@icloud.com`, `@gmail.com`) in Xcode.
3. **Quarantine Stripping (`xattr -cr`)** — Clearing the browser/download quarantine attribute so Gatekeeper allows immediate launch without security blocks.

KobeanQAUtils offers **two macOS desktop options**:
- **100% Pure Native macOS App (SwiftUI)** *(Recommended)*: **~2.5 MB** bundle, 100% native Apple design language (`NavigationSplitView`, searchable sidebar, native forms, CryptoKit, CoreImage), instant launch (< 0.05s), and ultra-low memory (~15 MB RAM vs 300MB+ in Electron). **Zero WebView / Zero Web dependencies.**
- **Electron Desktop App**: ~616 MB bundle, Chromium + Node.js runtime with CORS bypass.

---

## ⚡ Quick Comparison

| Feature | 🍏 Pure Native macOS App (SwiftUI) | ⚡ Desktop App (Electron) |
| :--- | :--- | :--- |
| **Technology** | **100% Pure Swift 6 / SwiftUI** (No WebView) | Node.js + Chromium + Electron 40 |
| **App Bundle Size** | **~2.5 MB** | ~616 MB |
| **Memory Footprint** | **~15–25 MB RAM** | ~300–450 MB RAM |
| **Launch Speed** | Instant (< 0.05s) | 1–2s |
| **Native Integration** | SplitView, Searchable, SF Symbols, CryptoKit | Web Wrapper |
| **Xcode Integration** | Full (`macos/KobeanQAUtils.xcodeproj`) | None |
| **Apple Dev Account Needed?** | **No** (Ad-Hoc / Personal Team) | **No** (Ad-Hoc / Local Cert) |
| **Install Location** | `/Applications/KobeanQAUtils.app` | `/Applications/KobeanQAUtils.app` |

---

## 🚀 Option 1: Pure Native macOS App (Recommended)

### Included Native QA Tools (21 Pure Swift Engines):
- **Converters & Formatters**:
  - Base64 Encoder / Decoder (Standard & URL-safe)
  - JSON Formatter & Validator (Prettify 2/4 spaces, Minify, syntax validation)
  - Unix Timestamp Converter (Live ticker, Epoch ➔ Human Date & vice-versa)
  - Color Converter (HEX, RGB, HSL, CMYK, SwiftUI Color code, WCAG AA/AAA contrast ratios)
  - Markdown to Confluence Wiki (Bidirectional Markdown ↔ Confluence/Jira wiki markup)
- **Encoding & Security**:
  - Hash & Checksum (MD5, SHA-1, SHA-256, SHA-384, SHA-512, HMAC via CryptoKit)
  - JWT Debugger (Token parsing, header/payload inspection & claim expiration evaluation)
  - Password Generator (Custom character sets, entropy score & bulk generation)
  - AES-256-GCM Encryption / Decryption (Authenticated encryption via CryptoKit, Base64/Hex output)
  - HTPasswd Generator (Apache/Nginx basic auth records via SHA-1, APR1-MD5, and multi-user lists)
- **Data & Generators**:
  - UUID / GUID Generator (Bulk v4 generation, lowercase/uppercase, hyphen toggles)
  - TOTP 2FA Authenticator (RFC 6238 Base32 TOTP with 30s animated circular countdown)
  - Text & Character Analyzer (Characters, words, sentences, lines, bytes, reading time)
  - Lorem Ipsum Generator (Paragraphs, sentences, words, bullet lists, HTML wrappers)
  - Dummy Data Generator (Realistic mock profiles with Luhn-valid credit cards, JSON/CSV/SQL export)
- **API & Network Testing**:
  - REST API Tester (GET, POST, PUT, DELETE, custom headers, response timing & formatted output)
  - WebSocket Client Tester (Native `URLSessionWebSocketTask` live traffic tester, ping/pong & logs)
- **Developer & QA Tools**:
  - Text Diff Comparator (Side-by-side / unified line-by-line differences)
  - QR Code Generator (CoreImage `CIFilter`, copy image, save PNG)
  - SQL Helper & Formatter (SQL keyword beautifier and mock INSERT query generator)
  - Test File Generator (Generate files of exact byte/KB/MB sizes with zeros, random bytes, text, CSV, or JSON)

### Method A: One-Command Automated Build & Install

Run one command in your terminal from the repository root:

```bash
npm run mac:install
# or: make mac-install
```

What this script (`scripts/install-native-mac.sh`) automatically does:
1. Generates the Xcode project using `xcodegen`.
2. Compiles the native Swift/SwiftUI application for Release (`arm64` Apple Silicon).
3. Compiles the native `Assets.car` and embeds brand icons.
4. Code-signs the bundle with Ad-Hoc ("Sign to Run Locally") and sandbox entitlements.
5. Copies the app into `/Applications/KobeanQAUtils.app`.
6. Strips macOS quarantine (`xattr -cr`) so Gatekeeper doesn't show any warning dialogs.
7. Registers with macOS LaunchServices so it appears in Spotlight and Launchpad.

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

### Method C: Fast Navigation & Instant Search

The native macOS app features an integrated sidebar search filter:
- Press **`⌘F`** or click the search field at the top of the sidebar.
- Type any tool name, keyword, or shortcut (e.g. `jwt`, `base64`, `hash`, `2fa`, `token`, `uuid`, `api`).
- Instant fuzzy filtering highlights matches across all categories.
- Built-in one-click clipboard copying with visual toast feedback.

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
