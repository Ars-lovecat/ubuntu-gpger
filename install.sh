#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.config/gpger"
LOG_DIR="$HOME/log"

echo "[gpger] 설치를 시작합니다..."

# 1. 실행 파일에 권한 부여
chmod +x "$SCRIPT_DIR/bin/gpger"

# 2. /usr/local/bin에 심볼릭 링크 생성
#    sudo의 secure_path에 포함된 위치라 'gpger'와 'sudo gpger' 둘 다 바로 동작함
#    (반대로 ~/.local/bin은 sudo가 못 찾아서 'sudo gpger apt ...'가 실패함)
TARGET_LINK="$BIN_DIR/gpger"

if [ -L "$TARGET_LINK" ]; then
    sudo rm "$TARGET_LINK"
elif [ -e "$TARGET_LINK" ]; then
    echo "[gpger] 경고: $TARGET_LINK 가 이미 존재하지만 심볼릭 링크가 아닙니다."
    echo "        직접 확인 후 제거하고 다시 설치해주세요."
    exit 1
fi

sudo ln -s "$SCRIPT_DIR/bin/gpger" "$TARGET_LINK"
echo "[gpger] $TARGET_LINK -> $SCRIPT_DIR/bin/gpger 링크 생성 완료"

# 3. 설정 폴더 확인, 없으면 생성 + 기본 설정 복사(기존 설정은 건드리지 않음)
if [ ! -d "$CONFIG_DIR" ]; then
    echo "[gpger] $CONFIG_DIR 이 없어 생성합니다."
    mkdir -p "$CONFIG_DIR"
fi

if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
    cp "$SCRIPT_DIR/config/config.default.yaml" "$CONFIG_DIR/config.yaml"
    echo "[gpger] 기본 설정을 $CONFIG_DIR/config.yaml 에 생성했습니다."
else
    echo "[gpger] 기존 설정($CONFIG_DIR/config.yaml)을 유지합니다."
fi

# 4. 로그 폴더 확인, 없으면 생성
if [ ! -d "$LOG_DIR" ]; then
    echo "[gpger] $LOG_DIR 이 없어 생성합니다."
    mkdir -p "$LOG_DIR"
fi

echo "[gpger] 설치 완료. 'gpger config' 로 설정을 확인/수정할 수 있습니다."
