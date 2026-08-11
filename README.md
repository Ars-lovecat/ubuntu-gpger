# gpger

GPG 공개키를 지정한 URL에서 받아 apt 소스에 자동 등록하는 우분투용 커맨드.

## 요구사항

- Python 3
- `python3-yaml` (`sudo apt install python3-yaml`)
- `gpg` (기본 설치되어 있음)

## 설치

```bash
git clone https://github.com/<사용자명>/gpger.git ~/.local/share/gpger
~/.local/share/gpger/install.sh
```

설치 중 `/usr/local/bin`에 심볼릭 링크를 만들기 위해 sudo 비밀번호를 한 번 물어봅니다. 이 위치는 sudo의 `secure_path`에 포함되어 있어서, 이후로는 `gpger`와 `sudo gpger` 둘 다 별도 PATH 설정 없이 바로 동작합니다.

## 업데이트

실행 파일은 심볼릭 링크라, 저장소를 pull하면 바로 반영됩니다.

```bash
cd ~/.local/share/gpger && git pull && ./install.sh
```

(`install.sh`를 다시 실행하는 이유: 링크/설정/로그 폴더가 없어졌을 경우를 대비한 재확인용이며, 기존 `config.yaml`은 덮어쓰지 않습니다.)

## 사용법

```bash
# 설정 파일을 편집기로 열기 (최초 실행 시 기본값 자동 생성)
gpger config

# 편집기 없이 설정 파일 경로와 내용만 확인
gpger config status

# GPG 키를 받아 apt 소스로 등록 (root 권한 필요)
sudo gpger apt <공개키 URL> <repo> <suite> <component>

# 예시
sudo gpger apt https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    https://cli.github.com/packages stable main
```

파일명(키/소스 파일의 이름)은 기본적으로 GPG 키의 UID에서 자동으로 추출됩니다. 추출에 실패하거나 원하는 이름을 직접 쓰고 싶으면 `--name`을 사용하세요.

```bash
sudo gpger apt <URL> stable main --name github
```

## 로그

`~/log/gpger.log`에 JSON 형식으로 기록되며, 100MB마다 최대 5개까지 gzip 압축되어 로테이션됩니다. `sudo`로 실행해도 실제 실행한 사용자의 홈 디렉토리를 기준으로 기록됩니다.

## 알려진 제한

- 최초 실행이 `sudo gpger apt ...`이고 `~/log`가 아직 없는 상태라면 로그 폴더/파일이 root 소유로 생성될 수 있습니다. `install.sh`를 먼저 실행해두면 로그 폴더가 사용자 소유로 미리 만들어져 이 문제를 피할 수 있습니다.
