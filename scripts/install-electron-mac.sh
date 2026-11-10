#!/usr/bin/env bash
set -e

# ==============================================================================
# KobeanQAUtils — Electron macOS App Installer for Local Testing
# No Paid Apple Developer Account Required!
# Re-signs with ad-hoc or local Apple Development certificate & strips quarantine
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

APP_NAME="KobeanQAUtils"
INSTALL_DIR="/Applications"
AUTO_LAUNCH=false

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}============================================================${NC}"
echo -e "${CYAN}${BOLD}⚡ KobeanQAUtils — Electron macOS App Installer${NC}"
echo -e "${BLUE}${BOLD}============================================================${NC}"

# Parse optional arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --launch|-l) AUTO_LAUNCH=true ;;
        --user|-u) INSTALL_DIR="${HOME}/Applications" ;;
        --identity|-i) CUSTOM_IDENTITY="$2"; shift ;;
        --help|-h)
            echo "Usage: ./scripts/install-electron-mac.sh [options]"
            echo ""
            echo "Options:"
            echo "  --launch, -l       Automatically launch the app after installing"
            echo "  --user, -u         Install to ~/Applications instead of /Applications"
            echo "  --identity, -i ID  Specify custom codesign identity"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *) echo -e "${YELLOW}Unknown option: $1${NC}" ;;
    esac
    shift
done

cd "${PROJECT_ROOT}"

# Step 1: Build Web Application Bundle with ELECTRON=true
echo -e "\n${BOLD}[1/5] Building Web Assets with Relative Paths (ELECTRON=true)...${NC}"
ELECTRON=true npm run build

# Step 2: Package Electron Application Unpacked
echo -e "\n${BOLD}[2/5] Packaging Electron Desktop Application...${NC}"
CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac --dir

ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    BUILT_DIR="${PROJECT_ROOT}/release/mac-arm64"
else
    BUILT_DIR="${PROJECT_ROOT}/release/mac"
fi

BUILT_APP="${BUILT_DIR}/${APP_NAME}.app"

if [ ! -d "${BUILT_APP}" ]; then
    # Fallback search
    BUILT_APP=$(find "${PROJECT_ROOT}/release" -name "${APP_NAME}.app" -maxdepth 2 | head -1)
fi

if [ ! -d "${BUILT_APP}" ]; then
    echo -e "${RED}✗ Error: Could not locate built Electron app in ${PROJECT_ROOT}/release${NC}"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Found packaged app at: ${BUILT_APP}"

# Step 3: Determine Code Signing Identity & Re-sign App
echo -e "\n${BOLD}[3/5] Applying Code Signature...${NC}"
SIGN_ID="-"

if [ -n "${CUSTOM_IDENTITY}" ]; then
    SIGN_ID="${CUSTOM_IDENTITY}"
    echo -e "  Using specified identity: ${SIGN_ID}"
else
    echo -e "  Using Ad-Hoc signature (${BOLD}Sign to Run Locally${NC}) - no Keychain prompt needed"
fi

ENTITLEMENTS="${PROJECT_ROOT}/buildResources/entitlements.mac.plist"

# Deep re-sign all frameworks, helpers, and the main bundle
codesign --force --deep --sign "${SIGN_ID}" \
    --entitlements "${ENTITLEMENTS}" \
    --timestamp=none \
    "${BUILT_APP}"

echo -e "  ${GREEN}✓${NC} App re-signed cleanly."

# Step 4: Install App
echo -e "\n${BOLD}[4/5] Installing to ${INSTALL_DIR}/${APP_NAME}.app...${NC}"
mkdir -p "${INSTALL_DIR}"
TARGET_APP="${INSTALL_DIR}/${APP_NAME}.app"

if [ -d "${TARGET_APP}" ]; then
    echo -e "  Removing existing installation..."
    rm -rf "${TARGET_APP}"
fi

cp -R "${BUILT_APP}" "${TARGET_APP}"

# Step 5: Strip Gatekeeper Quarantine & Register with LaunchServices
echo -e "\n${BOLD}[5/5] Removing Quarantine & Registering with macOS...${NC}"
xattr -cr "${TARGET_APP}" 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f "${TARGET_APP}" 2>/dev/null || true

# Verify
codesign --verify --deep --strict "${TARGET_APP}"

echo -e "\n${GREEN}${BOLD}============================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 KobeanQAUtils Electron App Successfully Installed!${NC}"
echo -e "${GREEN}${BOLD}============================================================${NC}"
echo -e "Location:   ${BOLD}${TARGET_APP}${NC}"
echo -e "Size:       $(du -sh "${TARGET_APP}" | cut -f1)"
echo -e "Signature:  Valid local signature (${SIGN_ID})"
echo -e "Gatekeeper: Cleared (ready to run with zero warnings)"
echo -e ""
echo -e "Launch via: ${CYAN}open \"${TARGET_APP}\"${NC}"

if [ "${AUTO_LAUNCH}" = "true" ]; then
    echo -e "\n${CYAN}Launching ${APP_NAME}...${NC}"
    open "${TARGET_APP}"
fi
