# gpger

GPG 공개키를 지정한 URL에서 받아 apt 소스에 자동 등록하는 우분투용 커맨드.

Claude Code가 만들었습니다. 문제 생기면 Claude를 탓하세요.

Ubuntu Server 24, 26 LTS 작동 확인했습니다.


## 요구사항

`python3`, `python3-yaml`, `gnupg`가 필요합니다.

없으면 `install.sh`가 설치 과정 중에 `[y/N]`으로 물어보고 동의하면 설치합니다.


## 설치 방법 두 가지

설치 경로가 두 가지 있습니다.

| | 직접 설치 | apt 설치 |
|---|---|---|
| 형태 | git clone + install.sh | .deb 패키지 |
| 배치 위치 | `~/.local/share/gpger` + `/usr/local/bin/gpger` | `/usr/lib/gpger` + `/usr/bin/gpger` |
| 갱신 | `git pull` | `apt upgrade` |

**둘 다 같은 머신에 설치하면 `/usr/local/bin`이 PATH상 `/usr/bin`보다 먼저라 git clone 쪽이 항상 우선됩니다.** 
apt로 변경하시는 경우 `sudo rm /usr/local/bin/gpger`로 기존 버전을 지우는 걸 권장합니다.

### A. git clone (직접 설치)

```bash
git clone https://github.com/Ars-lovecat/ubuntu-gpger.git ~/.local/share/gpger
~/.local/share/gpger/install.sh
```

설치 중 `/usr/local/bin`에 심볼릭 링크를 만들기 위해 sudo 비밀번호를 한 번 물어봅니다. 이 위치는 sudo의 `secure_path`에 포함되어 있어서, 이후로는 `gpger`와 `sudo gpger` 둘 다 별도 PATH 설정 없이 바로 동작합니다.

업데이트:
```bash
cd ~/.local/share/gpger && git pull && ./install.sh
```
(`install.sh`를 다시 실행하는 이유: 링크/설정/로그 폴더가 없어졌을 경우를 대비한 재확인용이며, 기존 `config.yaml`은 덮어쓰지 않습니다.)

### B. apt (.deb 패키지)

`packaging/deb/build.sh`로 빌드한 `.deb`를 사설 apt 저장소(aptly 등)에 올려두면, 클라이언트에서는:

```bash
sudo apt install gpger
```

로 설치하고, 이후에는 `sudo apt upgrade`로 갱신합니다. 

## 사용법

```bash
# 설정값 전체 조회
gpger config get

# 설정값 하나만 조회
gpger config get apt.paths.gpg_dir

# 설정값 변경 (목록, 구조체 변경 불가 / 스칼라 값만 가능)
gpger config set system.arch amd64

# 설정을 기본값으로 초기화
gpger config reset

# 시스템에 등록된 apt 키링 조회 (root 불필요)
gpger config ls

# GPG 키를 받아 apt 소스로 등록하고 apt update까지 실행 (root 권한 필요)
sudo gpger apt <공개키 URL> <repo> <suite> <component...>

# 예시
sudo gpger apt https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    https://cli.github.com/packages stable main
```

`component`는 하나만 오는 경우가 대부분이지만, 공식 문서에 여러 개 나열돼 있으면 그대로 이어붙여도 됩니다 (`main restricted universe`처럼 뒤에 오는 값을 전부 공백으로 합쳐서 `Components:`에 씁니다).

등록 후에는 자동으로 `apt update`까지 실행되고, 실패하면(예: suite/component 값이 실제 저장소와 안 맞아서 404) 어떤 파일을 확인해야 하는지 에러로 알려줍니다.

파일명(키/소스 파일의 이름)은 기본적으로 GPG 키의 UID에서 자동으로 추출됩니다. 추출에 실패하거나 원하는 이름을 직접 쓰고 싶으면 `--name`을 사용하세요. `--name`은 영문 소문자/숫자/점/밑줄/하이픈만 허용됩니다(`/`, `..` 등 경로 문자는 거부 — 지정한 폴더 밖에 파일이 생기는 걸 막기 위함).

```bash
sudo gpger apt <URL> stable main --name github
```

`suite`/`component` 같은 인자 자리에 `auto`를 넣으면 실행 시 우분투 코드네임(`/etc/os-release`의 `UBUNTU_CODENAME`, 없으면 `VERSION_CODENAME`, 예: `noble`)으로 자동 치환됩니다. 도커처럼 OS 코드네임을 그대로 suite로 쓰는 저장소에 유용합니다.

```bash
sudo gpger apt https://download.docker.com/linux/ubuntu/gpg \
    https://download.docker.com/linux/ubuntu auto stable
```

## config ls — 시스템 키링 현황 조회

`gpger`로 등록한 것뿐 아니라 시스템에 있는 apt 관련 키링 전체를 훑어서 아래 6개 섹션(제목 밑줄로 구분)으로 분류해 보여줍니다. 분류 우선순위는 위에서부터입니다 — 즉 `/etc/apt/trusted.gpg.d/`에 있으면 무조건 "신뢰됨"이고, `ubuntu-*` 이름이라도 signed-by로 참조 중이면 "서명됨" 쪽에 남습니다. "Ubuntu OS 공개키"는 그 두 조건에 안 걸리는(=원래는 "미사용"으로 잡혔을) `ubuntu-*` 이름의 키만 따로 뺀 것입니다.

1. **서명됨 (/etc/apt/keyrings/)** — 이 폴더의 키링 중 `signed-by`로 참조되는 것
2. **서명됨 (/usr/share/keyrings/)** — 위와 동일, 이 폴더 기준
3. **서명됨 (기타 경로)** — 그 외 경로에서 `signed-by`로 참조되는 키링
4. **신뢰됨 (/etc/apt/trusted.gpg.d, 레거시)** — `signed-by` 없이 모든 저장소에 암묵적으로 적용되는 예전 방식의 키링
5. **Ubuntu OS 공개키** — 위 어디에도 안 걸리면서 이름이 `ubuntu-`로 시작하는 키 (우분투가 기본 설치해두는 것들)
6. **미사용** — 나머지, 즉 참조도 안 되고 우분투 자체 키도 아닌 진짜 정리 후보

각 키링 옆 괄호 안에 그 키링을 참조하는 소스 파일명이 표시되며(터미널이면 자주색), 여러 소스가 참조하면 쉼표로 나열됩니다. `.list`(`signed-by=...`)와 `.sources`(`Signed-By: ...`) 형식을 둘 다 파싱합니다. 파일 읽기만 하므로 `sudo` 없이 실행합니다.

## 결과물

`/etc/apt/keyrings/<name>.gpg`와 `/etc/apt/sources.list.d/<name>.sources`(deb822 형식)가 생성됩니다. 위 도커 예시라면:

```
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: noble
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.gpg
```

## 로그

`~/log/gpger.log`에 JSON 형식으로 기록되며, 100MB마다 최대 5개까지 gzip 압축되어 로테이션됩니다. `sudo`로 실행해도 실제 실행한 사용자의 홈 디렉토리를 기준으로 기록됩니다.

`apt` 등록/`apt update` 결과뿐 아니라 `config get`/`set`/`reset`/`ls` 호출도 모두 기록됩니다 (조회한 키, 변경한 값 등). 이 때문에 `config` 명령들도 로그 폴더가 있어야 동작합니다.

## 필요한 폴더/파일이 없을 때

`install.sh`가 필요한 폴더(설정, 로그, `/etc/apt/keyrings`)를 전부 만들어두기 때문에 정상적으로는 마주칠 일이 없지만, 나중에 폴더가 지워지는 등의 이유로 없어졌다면 gpger가 실행 중에 감지해서 `[y/N]`으로 물어봅니다. `y`면 그 자리에서 만들고 진행하고, 그 외에는 에러로 종료합니다. `install.sh`가 없앤 게 아니라 사용자가 직접 config.yaml을 건드려서 문법이 깨진 경우는 이 자동 복구 대상이 아니라 바로 에러 종료하며, `gpger config reset`으로 기본값으로 되돌려야 합니다.

비대화형 환경(cron, 스크립트 등)에서 돌려야 해서 프롬프트에 답할 방법이 없다면 `-y`/`--yes`를 서브커맨드 앞에 붙이면 모든 확인 프롬프트에 자동으로 예로 응답합니다.

```bash
gpger -y config get
sudo gpger -y apt <URL> <repo> <suite> <component>
```

## 안전장치

- **다운로드**: 최초 URL과 리다이렉트된 최종 URL 모두 `https://`인지 확인(중간에 http로 다운그레이드되는 걸 방지), 응답 크기 5MB 상한.
- **입력값 검증**: `--name`은 경로 문자 거부, `repo`/`suite`/`component`/`arch`는 개행·NUL 문자 거부(생성되는 `.sources` 파일에 몰래 필드가 끼어드는 것 방지).
- **등록은 트랜잭션으로 처리**: 기존 `.gpg`/`.sources`를 덮어쓰기 전에 백업해두고, 이후 `apt update`가 실패하면 새로 쓴 내용을 버리고 이전 상태로 복원합니다(신규 등록이었다면 새로 만든 파일을 삭제). 즉 실패해도 기존에 잘 동작하던 저장소가 깨진 채로 남지 않습니다.
- 파일 쓰기는 임시 파일 + `os.replace()`로 원자적으로 처리합니다.

## 종료 코드

| 코드 | 의미 |
|---|---|
| 0 | 성공 |
| 1 | 일반 오류 |
| 2 | 사용법 오류 (인자 잘못됨) |
| 10 | 설정 오류 (폴더/파일 없음, 문법 깨짐, 알 수 없는 키) |
| 20 | 권한 오류 (root 아님) |
| 30 | 네트워크 오류 (다운로드 실패) |
| 40 | GPG 오류 (dearmor/키 파싱 실패) |
| 50 | 파일시스템 오류 |
| 60 | apt update 실패 |

## 라이선스

[MIT](LICENSE)
