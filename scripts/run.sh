#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

# 백그라운드 기존 프로세스 종료
pkill -f "AgyBar" 2>/dev/null || true

# 실행
echo "🚀 AgyBar 메뉴바 앱 시작 중..."
nohup .build/debug/AgyBar > /dev/null 2>&1 &
echo "✅ AgyBar가 Mac 상단 메뉴바에 상주 기동되었습니다! (PID: $!)"
