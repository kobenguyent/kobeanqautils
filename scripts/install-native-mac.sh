#!/usr/bin/env bash
set -e

# ==============================================================================
# KobeanQAUtils — Native macOS App Installer for Local Testing
# No Paid Apple Developer Account Required!
# Uses Ad-Hoc codesigning or local Apple Development certificate
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
NC='\033[0m' # No Color

echo -e "${BLUE}${BOLD}============================================================${NC}"
echo -e "${CYAN}${BOLD}🍎 KobeanQAUtils — Native macOS App Installer${NC}"
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
            echo "  --identity, -i ID  Specify custom codesign identity (default: auto-detect)"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *) echo -e "${YELLOW}Unknown option: $1${NC}" ;;
    esac
    shift
done

cd "${PROJECT_ROOT}"

# Step 1: Detect Xcode Developer Directory
echo -e "\n${BOLD}[1/7] Checking Developer Tools...${NC}"
if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    echo -e "  ${GREEN}✓${NC} Using Xcode: $($DEVELOPER_DIR/usr/bin/xcodebuild -version | tr '\n' ' ')"
else
    echo -e "  ${YELLOW}!${NC} Xcode.app not found in /Applications; falling back to command-line tools"
fi

# Step 2: Build Web Application Bundle (dist)
echo -e "\n${BOLD}[2/7] Building Web Assets (dist)...${NC}"
if [ ! -d "${PROJECT_ROOT}/dist" ] || [ "${FORCE_BUILD:-false}" = "true" ]; then
    echo -e "  Building React web app with Vite..."
    npm run build
else
    echo -e "  ${GREEN}✓${NC} Found existing dist bundle. (Run 'npm run build' to recompile frontend if changed)."
fi

# Step 3: Generate Xcode Project via XcodeGen
echo -e "\n${BOLD}[3/7] Generating Xcode Project...${NC}"
if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate --spec "${MACOS_DIR}/project.yml" >/dev/null
    echo -e "  ${GREEN}✓${NC} Project generated at: ${MACOS_DIR}/${APP_NAME}.xcodeproj"
else
    echo -e "  ${YELLOW}!${NC} xcodegen not found in PATH; skipping project regeneration."
fi

# Step 4: Build Native macOS App
echo -e "\n${BOLD}[4/7] Compiling Native App (${BUILD_CONFIG})...${NC}"
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
    # Package into .app structure
    SWIFT_BIN="${MACOS_DIR}/.build/release/${APP_NAME}"
    BUILT_APP="${MACOS_DIR}/.build/${APP_NAME}.app"
    rm -rf "${BUILT_APP}"
    mkdir -p "${BUILT_APP}/Contents/MacOS" "${BUILT_APP}/Contents/Resources"
    cp "${SWIFT_BIN}" "${BUILT_APP}/Contents/MacOS/${APP_NAME}"
    cp "${MACOS_DIR}/Resources/Info.plist" "${BUILT_APP}/Contents/Info.plist"
    cp "${MACOS_DIR}/Resources/AppIcon.icns" "${BUILT_APP}/Contents/Resources/AppIcon.icns" 2>/dev/null || true
fi

if [ ! -d "${BUILT_APP}" ]; then
    echo -e "${RED}✗ Build failed: Could not find built app bundle at ${BUILT_APP}${NC}"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Built bundle ready: ${BUILT_APP}"

# Step 5: Bundle Web Assets into App
echo -e "\n${BOLD}[5/7] Embedding Web Assets & Resources...${NC}"
mkdir -p "${BUILT_APP}/Contents/Resources/dist"
rsync -a --delete "${PROJECT_ROOT}/dist/" "${BUILT_APP}/Contents/Resources/dist/"
echo -e "  ${GREEN}✓${NC} Web assets successfully embedded into application bundle."

# Step 6: Code Signing (Ad-Hoc / Sign to Run Locally by default)
echo -e "\n${BOLD}[6/7] Code Signing Application...${NC}"
SIGN_ID="-"

if [ -n "${CUSTOM_IDENTITY}" ]; then
    SIGN_ID="${CUSTOM_IDENTITY}"
    echo -e "  Using specified identity: ${SIGN_ID}"
else
    echo -e "  Using Ad-Hoc signature (${BOLD}Sign to Run Locally${NC}) - no Keychain prompt needed"
fi

ENTITLEMENTS="${MACOS_DIR}/Resources/KobeanQAUtils.entitlements"

# Force deep resign
codesign --force --deep --sign "${SIGN_ID}" \
    --entitlements "${ENTITLEMENTS}" \
    --timestamp=none \
    "${BUILT_APP}"

echo -e "  ${GREEN}✓${NC} Signed successfully."

# Step 7: Install to Target Directory
echo -e "\n${BOLD}[7/7] Installing to ${INSTALL_DIR}/${APP_NAME}.app...${NC}"
mkdir -p "${INSTALL_DIR}"
TARGET_APP="${INSTALL_DIR}/${APP_NAME}.app"

# Remove existing version if running or present
if [ -d "${TARGET_APP}" ]; then
    echo -e "  Removing existing installation..."
    rm -rf "${TARGET_APP}"
fi

cp -R "${BUILT_APP}" "${TARGET_APP}"

# Remove quarantine extended attributes (Gatekeeper bypass for local apps)
echo -e "  Removing Gatekeeper quarantine attributes..."
xattr -cr "${TARGET_APP}" 2>/dev/null || true

# Register with LaunchServices so Spotlight, Dock, and Finder recognize it
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f "${TARGET_APP}" 2>/dev/null || true

# Verify code signature
echo -e "  Verifying installed application signature..."
codesign --verify --deep --strict "${TARGET_APP}"

echo -e "\n${GREEN}${BOLD}============================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 KobeanQAUtils Native macOS App Successfully Installed!${NC}"
echo -e "${GREEN}${BOLD}============================================================${NC}"
echo -e "Location:  ${BOLD}${TARGET_APP}${NC}"
echo -e "Size:      $(du -sh "${TARGET_APP}" | cut -f1)"
echo -e "Signature: Valid local signature (${SIGN_ID})"
echo -e "Gatekeeper: Cleared (ready to run with zero warnings)"
echo -e ""
echo -e "You can launch it anytime via:"
echo -e "  • ${CYAN}open \"${TARGET_APP}\"${NC}"
echo -e "  • Spotlight (${CMD}⌘+Space${NC} → type 'KobeanQAUtils')"
echo -e "  • Or open Xcode project: ${CYAN}open macos/KobeanQAUtils.xcodeproj${NC}"

if [ "${AUTO_LAUNCH}" = "true" ]; then
    echo -e "\n${CYAN}Launching ${APP_NAME}...${NC}"
    open "${TARGET_APP}"
fi
