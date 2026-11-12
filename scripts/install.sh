#!/usr/bin/env bash
# ==============================================================================
# AgyBar: One-click Installer for macOS
# Git 기반 간편 설치 및 LaunchAgent 자동 시작 등록 스크립트
# ==============================================================================

set -e

# ANSI Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}   🚀 AgyBar (Antigravity MenuBar Quota Tracker) 설치   ${NC}"
echo -e "${CYAN}======================================================${NC}"

# 1. macOS 검증
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}❌ AgyBar는 macOS 전용 메뉴바 애플리케이션입니다.${NC}"
    exit 1
fi

# 2. Antigravity 설치 여부 점검 (사전 감지)
if [[ -d "$HOME/.gemini" || -d "$HOME/.gemini/antigravity" ]]; then
    echo -e "${GREEN}✅ Antigravity 로컬 환경이 감지되었습니다.${NC}"
else
    echo -e "${YELLOW}⚠️ Antigravity 환경(~/.gemini)을 찾을 수 없습니다.${NC}"
    echo -e "${YELLOW}   AgyBar 설치 후 Antigravity를 실행하면 쿼터가 자동 연동됩니다.${NC}"
fi

# 3. 프로젝트 루트 확인
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

# 4. Swift 빌드 환경 확인
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Swift 컴파일러를 찾을 수 없습니다.${NC}"
    echo -e "   터미널에서 다음 명령어로 개발자 도구를 설치해주세요: xcode-select --install"
    exit 1
fi

# 5. Release 최적화 빌드
echo -e "${CYAN}🔨 AgyBar 릴리스 바이너리 빌드 중... (잠시만 기다려주세요)${NC}"
swift build -c release

# 6. ~/Applications/AgyBar.app 번들 조립
APP_DIR="$HOME/Applications/AgyBar.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$HOME/Applications"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 기존 실행 중인 AgyBar 종료
pkill -f "AgyBar" 2>/dev/null || true

# 바이너리 및 Info.plist 복사
cp -f ".build/release/AgyBar" "$MACOS_DIR/AgyBar"
chmod +x "$MACOS_DIR/AgyBar"

if [[ -f "Info.plist" ]]; then
    cp -f "Info.plist" "$CONTENTS_DIR/Info.plist"
fi

# macOS Gatekeeper 격리 해제 (Unsigned 앱 차단 방어)
xattr -cr "$APP_DIR" 2>/dev/null || true

echo -e "${GREEN}✅ $APP_DIR 번들 생성 완료!${NC}"

# 7. 부팅 시 자동 실행을 위한 LaunchAgent 등록
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$PLIST_DIR/com.debuggingmylife.agybar.plist"
mkdir -p "$PLIST_DIR"

cat <<EOF > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.debuggingmylife.agybar</string>
    <key>ProgramArguments</key>
    <array>
        <string>$MACOS_DIR/AgyBar</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF

# LaunchAgent 로드 (RunAtLoad=true로 인해 이때 백그라운드 프로세스가 자동 기동됨)
launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE" 2>/dev/null || true

# 프로세스 기동 확인 (launchctl로 기동되지 않은 경우에만 open 실행)
sleep 0.5
if ! pgrep -f "$MACOS_DIR/AgyBar" > /dev/null; then
    open "$APP_DIR"
fi

echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}🎉 AgyBar가 성공적으로 설치 및 상단 메뉴바에 기동되었습니다!${NC}"
echo -e "   - 설치 경로: ${CYAN}$APP_DIR${NC}"
echo -e "   - 자동 시작: ${CYAN}$PLIST_FILE (로그인 시 자동 실행)${NC}"
echo -e "   - 제거 방법: ${YELLOW}./scripts/uninstall.sh${NC}"
echo -e "${CYAN}======================================================${NC}"
