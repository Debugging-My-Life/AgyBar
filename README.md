# 🚀 AgyBar (Antigravity MenuBar Quota Tracker)

Google Antigravity 모델별(Argon, Flash 등) 실시간 잔여 쿼터와 지난 7일간의 사용량 추이를 macOS 상단 메뉴바에서 한눈에 모니터링하는 초경량 네이티브 앱입니다.

---

## ✨ 핵심 기능
- **상단 메뉴바 인라인 게이지**: 클릭 없이도 `⚡️70% 🚀93%`와 같이 핵심 모델 잔여량 실시간 노출
- **팝오버 대시보드**: 모델별 3색 원형 게이지(`CircularGaugeView`), 리셋 카운트다운 타이머
- **7일간 소모 추이 차트**: Apple Swift Charts 기반 일별 모델 사용량 막대 차트
- **Antigravity 0-Click 연동**: Antigravity가 설치된 Mac 환경(`~/.gemini`)을 자동 감지하여 별도 로그인 없이 즉시 동작
- **부팅 시 자동 시작**: macOS `LaunchAgent`를 통한 가벼운 백그라운드 자동 기동

---

## 💻 설치 방법 (어느 Mac에서나 원클릭 설치)

### 방법 1. Git을 통한 초간편 원클릭 설치 (권장)
터미널을 열고 아래 명령어를 입력하면 즉시 빌드 및 설치되어 메뉴바에 실행됩니다:

```bash
git clone https://github.com/Debugging-My-Life/AgyBar.git ~/AgyBar && cd ~/AgyBar && ./scripts/install.sh
```

> **원클릭 curl 설치:**
> ```bash
> curl -fsSL https://raw.githubusercontent.com/Debugging-My-Life/AgyBar/develop/scripts/install.sh | bash
> ```

### 방법 2. Homebrew를 통한 설치 (Formula 제공 예정)
```bash
brew tap Debugging-My-Life/tap
brew install agybar
```

---

## 🛑 제거 방법 (Uninstall)
```bash
cd ~/AgyBar && ./scripts/uninstall.sh
```

---

## 🛠️ 기술 스택
- **Language**: Swift 6 (macOS 13.0+)
- **UI Framework**: SwiftUI (`MenuBarExtra` + `Charts`) + AppKit
- **Architecture**: Role-Based Model Tiering Pipeline
- **Runtime Policy**: `NSApplication.ActivationPolicy.accessory` (순수 메뉴바 전용)
