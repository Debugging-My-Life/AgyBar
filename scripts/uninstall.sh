#!/usr/bin/env bash
# ==============================================================================
# AgyBar: Uninstaller for macOS
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${RED}🛑 AgyBar 제거를 시작합니다...${NC}"

# 1. 프로세스 종료
pkill -f "AgyBar" 2>/dev/null || true

# 2. LaunchAgent 언로드 및 삭제
PLIST_FILE="$HOME/Library/LaunchAgents/com.debuggingmylife.agybar.plist"
OLD_PLIST="$HOME/Library/LaunchAgents/com.pukoni.agybar.plist"
if [[ -f "$OLD_PLIST" ]]; then
    launchctl unload "$OLD_PLIST" 2>/dev/null || true
    rm -f "$OLD_PLIST"
fi
if [[ -f "$PLIST_FILE" ]]; then
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    rm -f "$PLIST_FILE"
    echo -e "${GREEN}✅ LaunchAgent 자동 시작 등록 해제 완료${NC}"
fi

# 3. ~/Applications/AgyBar.app 삭제
APP_DIR="$HOME/Applications/AgyBar.app"
if [[ -d "$APP_DIR" ]]; then
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✅ $APP_DIR 앱 번들 삭제 완료${NC}"
fi

# 4. 로컬 캐시/히스토리 삭제 여부 안내
echo -e "${CYAN}💡 로컬 히스토리 데이터(~/Library/Application Support/AgyBar)는 보존되었습니다.${NC}"
echo -e "${GREEN}🎉 AgyBar가 완전히 제거되었습니다.${NC}"
