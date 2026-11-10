#!/usr/bin/env bash
set -e

# ==============================================================================
# KobeanQAUtils — 100% Pure Native SwiftUI macOS App Installer
# No Hybrid WebView / No Electron / Pure Swift 6 & SwiftUI
# No Paid Apple Developer Account Required! (Uses Ad-Hoc signing)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MACOS_DIR="${PROJECT_ROOT}/macos"

APP_NAME="KobeanQAUtils"
BUNDLE_ID="com.kobenguyent.kobeanqautils"
INSTALL_DIR="/Applications"
AUTO_LAUNCH=false
BUILD_CONFIG="Release"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}============================================================${NC}"
echo -e "${CYAN}${BOLD}🍏 KobeanQAUtils — 100% Native SwiftUI macOS App Installer${NC}"
echo -e "${BLUE}${BOLD}============================================================${NC}"

# Parse optional arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --launch|-l) AUTO_LAUNCH=true ;;
        --user|-u) INSTALL_DIR="${HOME}/Applications" ;;
        --debug|-d) BUILD_CONFIG="Debug" ;;
        --identity|-i) CUSTOM_IDENTITY="$2"; shift ;;
        --help|-h)
            echo "Usage: ./scripts/install-native-mac.sh [options]"
            echo ""
            echo "Options:"
            echo "  --launch, -l       Automatically launch the app after installing"
            echo "  --user, -u         Install to ~/Applications instead of /Applications"
            echo "  --debug, -d        Build Debug configuration instead of Release"
            echo "  --identity, -i ID  Specify custom codesign identity (default: ad-hoc)"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *) echo -e "${YELLOW}Unknown option: $1${NC}" ;;
    esac
    shift
done

cd "${PROJECT_ROOT}"

# Step 1: Detect Developer Tools
echo -e "\n${BOLD}[1/5] Checking Developer Tools...${NC}"
if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    echo -e "  ${GREEN}✓${NC} Using Xcode: $($DEVELOPER_DIR/usr/bin/xcodebuild -version | tr '\n' ' ')"
fi

# Step 2: Generate Xcode Project
echo -e "\n${BOLD}[2/5] Generating Xcode Project via XcodeGen...${NC}"
if [ ! -f "${MACOS_DIR}/Resources/AppIcon.icns" ] && command -v python3 >/dev/null 2>&1; then
    echo -e "  Generating brand icon assets..."
    python3 "${SCRIPT_DIR}/generate-brand-assets.py" >/dev/null 2>&1 || true
fi
if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate --spec "${MACOS_DIR}/project.yml" >/dev/null
    echo -e "  ${GREEN}✓${NC} Xcode project ready: ${MACOS_DIR}/${APP_NAME}.xcodeproj"
fi

# Step 3: Compile Native Swift App
echo -e "\n${BOLD}[3/5] Compiling Pure Native App (${BUILD_CONFIG})...${NC}"
DERIVED_DATA="${MACOS_DIR}/.build-xcode"

if [ -n "$DEVELOPER_DIR" ] && [ -d "${MACOS_DIR}/${APP_NAME}.xcodeproj" ]; then
    "$DEVELOPER_DIR/usr/bin/xcodebuild" \
        -project "${MACOS_DIR}/${APP_NAME}.xcodeproj" \
        -scheme "${APP_NAME}" \
        -configuration "${BUILD_CONFIG}" \
        -derivedDataPath "${DERIVED_DATA}" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        build -quiet
    
    BUILT_APP="${DERIVED_DATA}/Build/Products/${BUILD_CONFIG}/${APP_NAME}.app"
else
    echo -e "  Building via Swift Package Manager..."
    swift build --package-path "${MACOS_DIR}" -c release
    SWIFT_BIN="${MACOS_DIR}/.build/release/${APP_NAME}"
    BUILT_APP="${MACOS_DIR}/.build/${APP_NAME}.app"
    rm -rf "${BUILT_APP}"
    mkdir -p "${BUILT_APP}/Contents/MacOS" "${BUILT_APP}/Contents/Resources"
    cp "${SWIFT_BIN}" "${BUILT_APP}/Contents/MacOS/${APP_NAME}"
    cp "${MACOS_DIR}/Resources/Info.plist" "${BUILT_APP}/Contents/Info.plist"
fi

if [ ! -d "${BUILT_APP}" ]; then
    echo -e "${RED}✗ Build failed: Could not find built app bundle at ${BUILT_APP}${NC}"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Built bundle ready: ${BUILT_APP}"

# Ensure brand icon files & metadata
cp "${MACOS_DIR}/Resources/AppIcon.icns" "${BUILT_APP}/Contents/Resources/AppIcon.icns" 2>/dev/null || true
cp "${MACOS_DIR}/Resources/AppIcon.png" "${BUILT_APP}/Contents/Resources/AppIcon.png" 2>/dev/null || true
cp "${MACOS_DIR}/Resources/AppLogo.png" "${BUILT_APP}/Contents/Resources/AppLogo.png" 2>/dev/null || true

/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "${BUILT_APP}/Contents/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "${BUILT_APP}/Contents/Info.plist" 2>/dev/null || true

/usr/libexec/PlistBuddy -c "Set :CFBundleIconName AppIcon" "${BUILT_APP}/Contents/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" "${BUILT_APP}/Contents/Info.plist" 2>/dev/null || true

# Step 4: Code Signing (Ad-Hoc / Sign to Run Locally)
echo -e "\n${BOLD}[4/5] Code Signing Application...${NC}"
SIGN_ID="-"
if [ -n "${CUSTOM_IDENTITY}" ]; then
    SIGN_ID="${CUSTOM_IDENTITY}"
    echo -e "  Using specified identity: ${SIGN_ID}"
else
    echo -e "  Using Ad-Hoc signature (${BOLD}Sign to Run Locally${NC})"
fi

ENTITLEMENTS="${MACOS_DIR}/Resources/KobeanQAUtils.entitlements"

codesign --force --deep --sign "${SIGN_ID}" \
    --entitlements "${ENTITLEMENTS}" \
    --timestamp=none \
    "${BUILT_APP}"

echo -e "  ${GREEN}✓${NC} Signed successfully."

# Step 5: Install to Target Directory
echo -e "\n${BOLD}[5/5] Installing to ${INSTALL_DIR}/${APP_NAME}.app...${NC}"
mkdir -p "${INSTALL_DIR}"
TARGET_APP="${INSTALL_DIR}/${APP_NAME}.app"

# Kill running instance if active before replacing
pkill -x "${APP_NAME}" 2>/dev/null || true
sleep 0.5

rm -rf "${TARGET_APP}"
cp -R "${BUILT_APP}" "${TARGET_APP}"

# Clear Gatekeeper quarantine attributes
xattr -cr "${TARGET_APP}" 2>/dev/null || true

# Register with LaunchServices & refresh Dock
touch "${TARGET_APP}"
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -r "${TARGET_APP}" 2>/dev/null || true
killall Dock 2>/dev/null || true

# Verify code signature
echo -e "  Verifying installed application signature..."
codesign --verify --deep --strict "${TARGET_APP}"

APP_SIZE=$(du -sh "${TARGET_APP}" | cut -f1)

echo -e "\n${GREEN}${BOLD}============================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 KobeanQAUtils 100% Native App Successfully Installed!${NC}"
echo -e "${GREEN}${BOLD}============================================================${NC}"
echo -e "Type:       ${BOLD}Pure Native SwiftUI (No WebView / No Electron)${NC}"
echo -e "Location:   ${BOLD}${TARGET_APP}${NC}"
echo -e "Size:       ${BOLD}${APP_SIZE}${NC} (ultra-lightweight)"
echo -e "Signature:  Valid local signature (${SIGN_ID})"
echo -e "Gatekeeper: Cleared (ready to run with zero warnings)"
echo -e ""
echo -e "Launch via:"
echo -e "  • ${CYAN}open \"${TARGET_APP}\"${NC}"
echo -e "  • Spotlight (${BOLD}⌘+Space${NC} → 'KobeanQAUtils')"
echo -e "  • Or open in Xcode: ${CYAN}open macos/KobeanQAUtils.xcodeproj${NC}"

if [ "${AUTO_LAUNCH}" = "true" ]; then
    echo -e "\n${CYAN}Launching ${APP_NAME}...${NC}"
    open "${TARGET_APP}"
fi
