# gpger

GPG 공개키를 지정한 URL에서 받아 apt 소스에 자동 등록하는 우분투용 커맨드.
공식 문서에 있는 외부 APT 저장소를 Ubuntu 서버에 편리하게 등록할 수 있습니다.

Claude Code가 만들었습니다. 문제 생기면 Claude를 탓하세요.

Ubuntu Server 24, 26 LTS 작동 확인했습니다.


## 요구사항

`python3`, `python3-yaml`, `gnupg`가 필요합니다.

없으면 `install.sh`가 설치 과정 중에 `[y/N]`으로 물어보고 동의하면 설치합니다.


## 설치 방법

gpger 저장소 자체는 gpger로 등록할 수 없습니다 (닭과 달걀 문제 — 처음엔 gpger가 없으니까요). 그래서 최초 등록만 아래처럼 수동으로 합니다. 다른 도구들의 공식 문서에 있는 방식과 동일합니다.

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://ars-lovecat.github.io/ubuntu-gpger/gpger-key.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gpger.gpg
echo "Types: deb
URIs: https://ars-lovecat.github.io/ubuntu-gpger
Suites: stable
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/gpger.gpg" | sudo tee /etc/apt/sources.list.d/gpger.sources
sudo apt update
sudo apt install gpger
```

이후부터는 `sudo apt upgrade`로 갱신합니다. (참고로 gpger가 설치된 이후에는, *다른* 저장소를 등록할 때는 이 수동 과정 대신 `sudo gpger apt ...` 한 줄로 끝납니다 — gpger 자신만 예외입니다.)


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

# 시스템에 등록된 apt 키링 조회
gpger config ls

# GPG 키를 받아 apt 소스로 등록하고 apt update까지 실행 (root 권한 필요)
sudo gpger apt <공개키 URL> <repo> <suite> <component...>

# 예시
sudo gpger apt https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    https://cli.github.com/packages stable main
```

공개키 URL, 버전 등은 각 CLI 도구의 공식 문서를 참고하세요.

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

`gpger`로 등록한 것뿐 아니라 시스템에 있는 apt 관련 키링 전체를 훑어서 아래 6개 섹션(제목 밑줄로 구분)으로 분류해 보여줍니다. 분류 우선순위는 위에서부터입니다 — 즉 `/etc/apt/trusted.gpg.d/`에 있으면 무조건 "신뢰됨"이고, `ubuntu-*` 이름이라도 signed-by로 참조 중이면 "서명됨" 쪽에 남습니다. "Ubuntu OS 공개키"는 그 두 조건에 안 걸리는(=원래는 "참조 미검출"로 잡혔을) `ubuntu-*` 이름의 키만 따로 뺀 것입니다.

1. **서명됨 (/etc/apt/keyrings/)** — 이 폴더의 키링 중 `signed-by`로 참조되는 것
2. **서명됨 (/usr/share/keyrings/)** — 위와 동일, 이 폴더 기준
3. **서명됨 (기타 경로)** — 그 외 경로에서 `signed-by`로 참조되는 키링
4. **신뢰됨 (/etc/apt/trusted.gpg.d, 레거시)** — `signed-by` 없이 모든 저장소에 암묵적으로 적용되는 예전 방식의 키링
5. **Ubuntu OS 공개키** — 위 어디에도 안 걸리면서 이름이 `ubuntu-`로 시작하는 키 (우분투가 기본 설치해두는 것들)
6. **참조 미검출** — 나머지. 실제로 안 쓰는 키일 수도 있지만, 지금 `signed-by` 파서가 한 줄짜리 절대경로만 인식해서 (여러 경로 나열, fingerprint 지정, 인라인 키, continuation line 등은 놓침) "확실히 미사용"이 아니라 "이 파서로는 참조를 못 찾았다"는 뜻입니다. 삭제 전에 직접 확인하세요.

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

`sudo gpger apt ...`를 실행할 때마다 로그 폴더/파일 소유권을 실행한 사용자로 되돌려놓기 때문에, root가 만들었어도 이후 sudo 없이 `gpger config ...`를 실행할 때 권한 오류가 나지 않습니다.

## 필요한 폴더/파일이 없을 때

`install.sh`가 필요한 폴더(설정, 로그, `/etc/apt/keyrings`)를 전부 만들어두기 때문에 정상적으로는 마주칠 일이 없지만, 나중에 폴더가 지워지는 등의 이유로 없어졌다면 gpger가 실행 중에 감지해서 `[y/N]`으로 물어봅니다. `y`면 그 자리에서 만들고 진행하고, 그 외에는 에러로 종료합니다. `install.sh`가 없앤 게 아니라 사용자가 직접 config.yaml을 건드려서 문법이 깨진 경우는 이 자동 복구 대상이 아니라 바로 에러 종료하며, `gpger config reset`으로 기본값으로 되돌려야 합니다.

비대화형 환경(cron, 스크립트 등)에서 돌려야 해서 프롬프트에 답할 방법이 없다면 `-y`/`--yes`를 서브커맨드 앞에 붙이면 모든 확인 프롬프트에 자동으로 예로 응답합니다.

```bash
gpger -y config get
sudo gpger -y apt <URL> <repo> <suite> <component>
```

## 안전장치

- **다운로드**: 최초 URL과 리다이렉트된 최종 URL 모두 `https://`인지 확인(중간에 http로 다운그레이드되는 걸 방지), 응답 크기 5MB 상한.
- **입력값 검증**: `--name`은 경로 문자 거부 + 64자 제한(UID에서 자동 추출한 이름도 동일하게 64자로 자름), `repo`/`suite`/`component`/`arch`는 개행·NUL 문자 거부(생성되는 `.sources` 파일에 몰래 필드가 끼어드는 것 방지).
- **등록은 트랜잭션으로 처리**: 기존 `.gpg`/`.sources`를 덮어쓰기 전에 백업해두고, 이후 `apt update`가 종료 코드로 실패하든 그 사이(파일 쓰기, apt 호출 등) 예외가 나든 새로 쓴 내용을 버리고 이전 상태로 복원합니다(신규 등록이었다면 새로 만든 파일을 삭제). 즉 실패해도 기존에 잘 동작하던 저장소가 깨진 채로 남지 않습니다.
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
