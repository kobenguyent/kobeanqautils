#!/usr/bin/env bash
set -e

# ==============================================================================
# KobeanQAUtils — Package Pure Native SwiftUI macOS App into DMG & ZIP
# Generates release artifacts for immediate user download or GitHub Releases
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MACOS_DIR="${PROJECT_ROOT}/macos"
RELEASE_DIR="${PROJECT_ROOT}/release"
DERIVED_DATA="${MACOS_DIR}/.build-xcode"

APP_NAME="KobeanQAUtils"
VERSION=$(node -p "require('${PROJECT_ROOT}/package.json').version" 2>/dev/null || echo "1.2.0")

# Terminal Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}============================================================${NC}"
echo -e "${CYAN}${BOLD}📦 KobeanQAUtils Native macOS Release Packager (v${VERSION})${NC}"
echo -e "${BLUE}${BOLD}============================================================${NC}"

# Step 1: Ensure fresh Release build exists
echo -e "\n${BOLD}[1/4] Building Release Native App Bundle...${NC}"
cd "${PROJECT_ROOT}"

# Run xcodegen if available
if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate --spec "${MACOS_DIR}/project.yml" >/dev/null
fi

if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

if [ -n "$DEVELOPER_DIR" ] && [ -d "${MACOS_DIR}/${APP_NAME}.xcodeproj" ]; then
    "$DEVELOPER_DIR/usr/bin/xcodebuild" \
        -project "${MACOS_DIR}/${APP_NAME}.xcodeproj" \
        -scheme "${APP_NAME}" \
        -configuration "Release" \
        -derivedDataPath "${DERIVED_DATA}" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        build -quiet
    BUILT_APP="${DERIVED_DATA}/Build/Products/Release/${APP_NAME}.app"
else
    echo "Xcode project build failed; checking fallback SPM build..."
    swift build --package-path "${MACOS_DIR}" -c release
    BUILT_APP="${MACOS_DIR}/.build/${APP_NAME}.app"
fi

if [ ! -d "${BUILT_APP}" ]; then
    echo "❌ Error: App bundle not found at ${BUILT_APP}"
    exit 1
fi

echo -e "  ${GREEN}✓${NC} Source bundle verified: ${BUILT_APP}"

# Step 2: Code signing & quarantine clearance
echo -e "\n${BOLD}[2/4] Signing and Securing App Bundle...${NC}"
codesign --force --deep --sign - --options runtime "${BUILT_APP}"
xattr -cr "${BUILT_APP}"
codesign --verify --deep --strict --verbose=1 "${BUILT_APP}"
echo -e "  ${GREEN}✓${NC} Ad-hoc signature verified."

# Step 3: Package into Release directory
echo -e "\n${BOLD}[3/4] Packaging Release Artifacts (.dmg & .zip)...${NC}"
mkdir -p "${RELEASE_DIR}"

ZIP_FILENAME="kobeanqautils-${VERSION}-native-macos.zip"
ZIP_ALIAS="KobeanQAUtils-Native-macOS.zip"
DMG_FILENAME="kobeanqautils-${VERSION}-native-macos.dmg"
DMG_ALIAS="KobeanQAUtils-Native-macOS.dmg"

# 3A: Create ZIP
echo -e "  Creating ZIP archive: ${ZIP_FILENAME}..."
(
    cd "$(dirname "${BUILT_APP}")"
    zip -r -q -y "${RELEASE_DIR}/${ZIP_FILENAME}" "$(basename "${BUILT_APP}")"
)
cp "${RELEASE_DIR}/${ZIP_FILENAME}" "${RELEASE_DIR}/${ZIP_ALIAS}"
echo -e "  ${GREEN}✓${NC} ZIP created: ${RELEASE_DIR}/${ZIP_FILENAME}"

# 3B: Create DMG with Applications drag-and-drop link
echo -e "  Creating DMG disk image: ${DMG_FILENAME}..."
DMG_STAGING="$(mktemp -d /tmp/kobean-dmg.XXXXXX)"
cp -R "${BUILT_APP}" "${DMG_STAGING}/${APP_NAME}.app"
ln -s /Applications "${DMG_STAGING}/Applications"

rm -f "${RELEASE_DIR}/${DMG_FILENAME}" "${RELEASE_DIR}/${DMG_ALIAS}"
hdiutil create \
    -volname "${APP_NAME} Native" \
    -srcfolder "${DMG_STAGING}" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "${RELEASE_DIR}/${DMG_FILENAME}" >/dev/null

rm -rf "${DMG_STAGING}"
cp "${RELEASE_DIR}/${DMG_FILENAME}" "${RELEASE_DIR}/${DMG_ALIAS}"
echo -e "  ${GREEN}✓${NC} DMG created: ${RELEASE_DIR}/${DMG_FILENAME}"

# Step 4: Generate Checksums
echo -e "\n${BOLD}[4/4] Generating SHA-256 Checksums...${NC}"
cd "${RELEASE_DIR}"
shasum -a 256 "${DMG_FILENAME}" > "${DMG_FILENAME}.sha256"
shasum -a 256 "${ZIP_FILENAME}" > "${ZIP_FILENAME}.sha256"
cp "${DMG_FILENAME}.sha256" "${DMG_ALIAS}.sha256"
cp "${ZIP_FILENAME}.sha256" "${ZIP_ALIAS}.sha256"

DMG_SIZE=$(du -sh "${DMG_FILENAME}" | cut -f1)
ZIP_SIZE=$(du -sh "${ZIP_FILENAME}" | cut -f1)

echo -e "\n${BLUE}${BOLD}============================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 Native macOS Release Artifacts Ready!${NC}"
echo -e "${BLUE}${BOLD}============================================================${NC}"
echo -e "Version:     ${BOLD}v${VERSION}${NC}"
echo -e "Location:    ${BOLD}${RELEASE_DIR}${NC}"
echo -e "  • ${BOLD}${DMG_FILENAME}${NC} (${DMG_SIZE}) — Drag-and-drop Disk Image (User-facing)"
echo -e "  • ${BOLD}${ZIP_FILENAME}${NC} (${ZIP_SIZE}) — Compressed App Bundle"
echo -e "  • SHA-256:   ${BOLD}${DMG_FILENAME}.sha256${NC}"
echo -e "\nReady for direct download or publishing to GitHub Releases!"
