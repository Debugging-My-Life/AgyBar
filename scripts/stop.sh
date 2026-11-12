#!/bin/bash
echo "🛑 AgyBar 종료 중..."
pkill -f "AgyBar" && echo "✅ AgyBar가 정상 종료되었습니다." || echo "ℹ️ 실행 중인 AgyBar가 없습니다."
