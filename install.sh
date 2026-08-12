#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.config/gpger"
LOG_DIR="$HOME/log"
GPG_KEYRING_DIR="/etc/apt/keyrings"

echo "[gpger] 설치를 시작합니다..."

# 0. 필수 의존성 확인 및 설치
MISSING=()
command -v python3 >/dev/null 2>&1 || MISSING+=("python3")
command -v gpg >/dev/null 2>&1 || MISSING+=("gnupg")
if ! command -v python3 >/dev/null 2>&1 || ! python3 -c "import yaml" >/dev/null 2>&1; then
    MISSING+=("python3-yaml")
fi
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "[gpger] 다음 패키지가 없습니다: ${MISSING[*]}"
    read -r -p "[gpger] 지금 설치할까요? [y/N] " REPLY
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        echo "[gpger] 필수 패키지가 없어 설치를 진행할 수 없습니다."
        exit 1
    fi
    sudo apt-get update
    sudo apt-get install -y "${MISSING[@]}"
fi

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

# 5. apt keyrings 폴더 확인, 없으면 생성 (시스템 폴더라 sudo 필요)
if [ ! -d "$GPG_KEYRING_DIR" ]; then
    echo "[gpger] $GPG_KEYRING_DIR 이 없어 생성합니다."
    sudo mkdir -p "$GPG_KEYRING_DIR"
fi

echo "[gpger] 설치 완료. 'gpger config get' 으로 설정을 확인할 수 있습니다."
