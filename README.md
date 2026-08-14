# 1. gpger

### 1) 설명
GPG 공개키를 지정한 URL에서 받아 apt 소스에 자동 등록하는 우분투용 커맨드.
공식 문서에 있는 외부 APT 저장소를 Ubuntu 서버에 편리하게 등록할 수 있습니다. 개인 사용자용.

Claude Code가 만들었습니다. 문제 생기면 Claude를 탓하세요.

Ubuntu Server 24, 26 LTS 작동 확인했습니다.

### 2) 주 활용 예시
```bash
# 원래 버전 (출처 : Github Cli 공식 문서)
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y

# gpger 사용 시
sudo gpger apt https://cli.github.com/packages/githubcli-archive-keyring.gpg https://cli.github.com/packages stable main 
```

# 2. 설치 안내

### 1) 요구사항

`python3`, `python3-yaml`, `gnupg` 가 반드시 필요합니다.


### 2) 설치 방법

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

### 3) 업그레이드

```bash
sudo apt update
sudo apt upgrade
```

# 3. 사용법

### 1) Keyring 등록

GPG 키를 받아 apt 소스로 등록하고 apt update까지 실행 (root 권한 필요)

```bash
# 형태
sudo gpger apt <공개키 URL> <REPO> <SUITE> <COMPONENT...> --name <NAME>

# 예시
sudo gpger apt https://download.docker.com/linux/ubuntu/gpg \
    https://download.docker.com/linux/ubuntu auto stable --name docker

# 결과물
`/etc/apt/keyrings/<name>.gpg`와 `/etc/apt/sources.list.d/<name>.sources`(deb822 형식)가 생성됩니다.
```

공개키 URL, 버전 등은 각 CLI 도구의 공식 문서를 참고하세요.

`component`는 하나만 오는 경우가 대부분이지만, 공식 문서에 여러 개 나열돼 있으면 그대로 이어붙여도 됩니다 (`main restricted universe`처럼 뒤에 오는 값을 전부 공백으로 합쳐서 `Components:`에 씁니다).

파일명(키/소스 파일의 이름)은 기본적으로 GPG 키의 UID에서 자동으로 추출됩니다. 
추출에 실패하거나 원하는 이름을 직접 쓰고 싶으면 `--name`을 사용하세요 (영문 소문자, 숫자, 점, 밑줄, 하이픈만 가능)

`suite`/`component` 같은 인자 자리에 `auto`를 넣으면 실행 시 우분투 코드네임(`/etc/os-release`의 `UBUNTU_CODENAME`, 없으면 `VERSION_CODENAME`, 예: `noble`)으로 자동 치환됩니다. 도커처럼 OS 코드네임을 그대로 suite로 쓰는 저장소에 유용합니다.

### 2) Keyring 조회

apt 관련 keyring 전체를 훑어서 아래 6개 섹션(제목 밑줄로 구분)으로 분류하여 출력. 분류 우선순위는 위에서부터.

```bash
# 시스템에 등록된 apt keyring 조회
gpger list
gpger ls
```

각 keyring 옆 괄호 안에 그 keyring을 참조하는 소스 파일명이 표시되며(터미널이면 자주색), 여러 소스가 참조하면 쉼표로 나열됩니다. 

`.list`(`signed-by=...`)와 `.sources`(`Signed-By: ...`) 형식을 둘 다 파싱합니다.

1. **서명됨 (/etc/apt/keyrings/)** — 이 폴더의 keyring 중 `signed-by`로 참조되는 것
2. **서명됨 (/usr/share/keyrings/)** — 이 폴더의 keyring 중 `signed-by`로 참조되는 것
3. **서명됨 (기타 경로)** — 그 외 경로의 keyring 중 `signed-by`로 참조되는 것
4. **신뢰됨 (/etc/apt/trusted.gpg.d, 레거시)** — 이 폴더에 있는 keyring (전역 신뢰, 레거시 방식)
5. **Ubuntu OS 공개키** — 그 이외의 keyring 중 이름이 `ubuntu-`로 시작하는 키 (우분투가 기본 설치해두는 것들)
6. **참조 미검출** — 나머지. 실제로 안 쓰는 키일 수도 있지만, 지금 `signed-by` 파서가 한 줄짜리 절대경로만 인식해서 (여러 경로 나열, fingerprint 지정, 인라인 키, continuation line 등은 놓침) "확실히 미사용"이 아니라 "이 파서로는 참조를 못 찾았다"는 뜻입니다. 삭제 전에 직접 확인하세요.

### 3) Keyring / Source 삭제

시스템에 등록된 apt keyring 삭제 (root 권한 필요)

```bash
# keyring + source 삭제
sudo gpger remove <KEYRING>
sudo gpger remove -a <KEYRING>
sudo gpger remove --all <KEYRING>

# keyring만 삭제
sudo gpger remove -k <KEYRING>
sudo gpger remove --keyring <KEYRING>

# source만 삭제
sudo gpger remove -s <SOURCE>
sudo gpger remove --source <SOURCE>

# 예시
sudo gpger remove githubcli-archive-keyring
sudo gpger remove githubcli-archive-keyring.gpg
```

`/etc/apt/keyrings/<name>.gpg`와 `/etc/apt/sources.list.d/<name>.sources` 중 존재하는 파일을 확인해서 `[y/N]`으로 물어본 뒤 삭제하고, 삭제 후 `apt update`까지 실행합니다.

일반적인 개인 사용자라면 옵션을 사용할 일은 없습니다. 그냥 커맨드만 사용하세요. 옵션 삭제로 인해 발생하는 오류는 수동으로 잡으셔야 합니다.

삭제 자체는 확인 즉시 끝나는 동작이라, 이후 `apt update`가 (이 삭제와 무관한 다른 저장소 문제로) 실패해도 방금 지운 파일을 되살리지는 않습니다.

apt의 `Signed-By`는 여러 keyring을 나열해서 OR로 인증하는 것도 지원합니다. 그래서 지금 지우려는 keyring을 **다른** `.sources`/`.list` 파일도 참조하고 있다면(`gpger list`로 확인 가능), 그쪽 인증이 깨지지 않도록 keyring은 자동으로 삭제하지 않고 경고만 표시합니다 (`-k`/`--keyring`, `-a`/`--all` 둘 다 해당).


### 4) 설정 관리

```bash
# 설정값 전체 조회
gpger config get

# 설정값 하나만 조회
gpger config get <CONFIG>

# 예시
gpger config get apt.paths.gpg_dir

------

# 설정값 변경
gpger config set <CONFIG> <VALUE>

# 예시
gpger config set system.arch amd64

------

# 설정 파일(config.yaml)을 기본값으로 초기화
gpger config reset
```

개인 사용자 단위에서는 사실상 건드릴 일이 없습니다.

### 5) 로그

`~/log/gpger.log`에 JSON 형식으로 기록되며, 100MB마다 최대 5개까지 gzip 압축되어 로테이션됩니다. `sudo`로 실행해도 실제 실행한 사용자의 홈 디렉토리를 기준으로 기록됩니다.

`apt` 등록/`apt update` 결과뿐 아니라 `config get`/`set`/`reset`/`ls` 호출도 모두 기록됩니다 (조회한 키, 변경한 값 등). 이 때문에 `config` 명령들도 로그 폴더가 있어야 동작합니다.

`sudo gpger apt ...`를 실행할 때마다 로그 폴더/파일 소유권을 실행한 사용자로 되돌려놓기 때문에, root가 만들었어도 이후 sudo 없이 `gpger config ...`를 실행할 때 권한 오류가 나지 않습니다.

### 6) 기타 사항

* 글로벌 옵션
  
  `-h`/`--help` : 도움말을 출력합니다.
  
  `-y`/`--yes` : 모든 확인 프롬프트에 자동으로 예로 응답합니다.

* 필요한 폴더/파일이 없을 때
  
  최초 설치 시 필요한 폴더(설정, 로그, `/etc/apt/keyrings` 등)을 전부 만들어두기 때문에 정상적으로는 마주칠 일이 없습니다.
  
  나중에 폴더가 지워지는 등의 이유로 없어졌다면 gpger가 실행 중에 감지해서 `[y/N]`으로 물어봅니다. (`y`면 즉시 기본 파일, 폴더 생성)
  
  사용자가 수동으로 config.yaml을 건드려서 문법이 깨진 경우는 즉시 에러 종료하며, 직접 수동으로 수정하시거나 `gpger config reset`으로 기본값으로 되돌려야 합니다.

## 안전장치

- **다운로드**: 최초 URL과 리다이렉트된 최종 URL 모두 `https://`인지 확인(중간에 http로 다운그레이드되는 걸 방지), 응답 크기 5MB 상한.
- **입력값 검증**: `--name`은 경로 문자 거부 + 64자 제한(UID에서 자동 추출한 이름도 동일하게 64자로 자름), `repo`/`suite`/`component`/`arch`는 개행·NUL 문자 거부(생성되는 `.sources` 파일에 몰래 필드가 끼어드는 것 방지).
- **등록은 트랜잭션으로 처리**: 기존 `.gpg`/`.sources`를 덮어쓰기 전에 백업해두고, 이후 `apt update`가 종료 코드로 실패하든 그 사이(파일 쓰기, apt 호출 등) 예외가 나든 새로 쓴 내용을 버리고 이전 상태로 복원합니다(신규 등록이었다면 새로 만든 파일을 삭제). 즉 실패해도 기존에 잘 동작하던 저장소가 깨진 채로 남지 않습니다.
- 파일 쓰기는 임시 파일 + `os.replace()`로 원자적으로 처리합니다.

라고 하네요.

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
