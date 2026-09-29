# 잇다 배포본

잇다 서버(백엔드), 화면(프론트엔드), AI 모델을 한 폴더에 모은 배포본이다. 서버 하나만 켜면 브라우저에서 바로 쓸 수 있다.

## 폴더 구조

```text
itda-release/
├─ backend/     # itda-backend의 app/, config/, demo/ + requirements.txt
├─ static/      # itda-frontend 빌드 결과 (dist/)
├─ model/       # Modelfile + .gguf 모델 파일 (.gguf는 git 제외, 별도 전달)
├─ build.sh     # 개발자 PC용: 세 레포에서 빌드해 위 폴더를 채움
├─ setup.sh     # 최초 1회: 가상환경 생성, 패키지 설치, Ollama 모델 등록
└─ run.sh       # 매번: Ollama 확인 후 서버 실행
```

## 준비물

- Python 3.12 이상. Ubuntu라면 `python3-venv`도 설치해야 한다(`sudo apt install python3-venv`).
- [Ollama](https://ollama.com/download)
- 따로 전달받은 `.gguf` 모델 파일

## 처음 한 번

```bash
# 1. 전달받은 .gguf 파일을 model/ 폴더에 넣는다
cd itda-release
./setup.sh
```

`setup.sh`는 다음을 한다.

1. `.venv` 가상환경을 만들고 `backend/requirements.txt`로 패키지를 설치한다.
2. Ollama 서버가 꺼져 있으면 켠다.
3. `model/Modelfile`로 모델을 Ollama에 등록한다. 등록 이름은 `backend/config/settings.yaml`의 `model_name`이다.

Python 3.12가 기본 `python3`이 아니면 직접 지정한다: `PYTHON=python3.12 ./setup.sh`

## 실행

```bash
./run.sh
```

브라우저에서 http://127.0.0.1:8000 을 연다. 서버는 터미널에서 `Ctrl+C`로 끈다.

| 용도 | 명령 |
| --- | --- |
| 기본 실행 | `./run.sh` |
| 발표용 데모 DB로 실행 | `ITDA_DB=demo.db ./run.sh` |
| API 문서 | http://127.0.0.1:8000/docs |

- 기록은 `backend/itda.db`에 저장된다(처음 실행할 때 생김).
- Ollama가 꺼져 있으면 `run.sh`가 켠다. 로그는 `ollama.log`에 남는다.

## 개발자: 배포본 새로 만들기

`itda-backend`, `itda-frontend`, `itda-model`이 이 폴더 옆(`../`)에 있어야 한다.

```bash
./build.sh                  # backend/, static/, model/ 을 새로 채움
SKIP_GGUF=1 ./build.sh      # 큰 .gguf 복사는 건너뜀 (Modelfile만 갱신)
```

레포 위치가 다르면 `BACKEND_REPO`, `FRONTEND_REPO`, `MODEL_REPO`로 경로를 지정한다.

- `backend/`와 `static/`은 빌드할 때마다 지워지고 다시 만들어진다. 수정은 원본 레포에서 한다.
- `backend/requirements.txt`는 itda-backend의 `uv.lock`에서 만든다(개발용 패키지 제외, 버전 고정). 이 파일을 직접 고치지 않는다.
- 이 빌드 과정에는 uv와 pnpm이 필요하다.

## 문제 해결

| 증상 | 해결 |
| --- | --- |
| `venv 생성 실패` | `sudo apt install python3-venv` 후 `./setup.sh` 다시 실행 |
| `model/….gguf 파일이 없습니다` | 전달받은 .gguf 파일을 `model/`에 넣는다 |
| `모델 '…' 이 등록되지 않았습니다` | `./setup.sh` 다시 실행 |
| `Ollama 서버가 응답하지 않습니다` | `ollama serve`를 직접 실행해 오류 확인 |
| 포트 8000이 이미 사용 중 | 다른 잇다 서버(개발용 등)가 켜져 있는지 확인하고 끈다 |

## Git 관리 범위

| 구분 | 대상 |
| --- | --- |
| 공유 | `backend/`, `static/`, `model/Modelfile`, 스크립트, `README.md` |
| 제외 | `.venv/`, `*.db`, `model/*.gguf`, `backend/static`(실행 시 만드는 링크), `ollama.log` |
