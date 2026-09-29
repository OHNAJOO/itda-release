#!/usr/bin/env bash
# 최초 1회: .venv 생성, 패키지 설치, Ollama에 모델 등록.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
# Python 3.12 이상 (PYTHON=... 으로 직접 지정 가능)
if [ -z "${PYTHON:-}" ]; then
  for p in python3.12 python3.13 python3; do command -v "$p" >/dev/null && { PYTHON="$p"; break; }; done
fi
"${PYTHON:?Python이 없습니다}" -c 'import sys; sys.exit(sys.version_info < (3, 12))' \
  || { echo "Python 3.12 이상이 필요합니다. (PYTHON=python3.12 ./setup.sh 로 지정 가능)" >&2; exit 1; }
command -v ollama >/dev/null || { echo "Ollama가 설치되어 있지 않습니다: https://ollama.com/download" >&2; exit 1; }

echo "==> 가상환경 (.venv, $PYTHON)"
if [ ! -x .venv/bin/pip ]; then
  rm -rf .venv
  "$PYTHON" -m venv .venv || {
    rm -rf .venv
    echo "venv 생성 실패. Ubuntu라면: sudo apt install python3-venv (또는 python3.12-venv)" >&2
    exit 1
  }
fi
.venv/bin/pip install --upgrade pip -q
.venv/bin/pip install -r backend/requirements.txt

echo "==> Ollama 모델 등록"
if ! ollama list >/dev/null 2>&1; then
  echo "Ollama 서버를 시작합니다 (로그: ollama.log)"
  nohup ollama serve >ollama.log 2>&1 &
  for _ in $(seq 30); do ollama list >/dev/null 2>&1 && break; sleep 1; done
  ollama list >/dev/null 2>&1 || { echo "Ollama 서버가 응답하지 않습니다." >&2; exit 1; }
fi

GGUF="$(sed -n 's|^FROM \./||p' model/Modelfile | head -1)"
[ -f "model/$GGUF" ] || { echo "model/$GGUF 파일이 없습니다. 별도로 전달받은 파일을 model/에 넣으세요." >&2; exit 1; }

read_setting() { .venv/bin/python -c "import yaml; print(yaml.safe_load(open('backend/config/settings.yaml'))['$1'])"; }
MODEL="$(read_setting model_name)"
SUMMARY_MODEL="$(read_setting summary_model)"

(cd model && ollama create "$MODEL" -f Modelfile)

if [ "$SUMMARY_MODEL" != "$MODEL" ] && ! ollama show "$SUMMARY_MODEL" >/dev/null 2>&1; then
  echo "주의: 요약 모델 '$SUMMARY_MODEL' 이 없습니다. 요약은 템플릿 문장으로 대신 나옵니다." >&2
fi

echo "완료. 이제 ./run.sh 로 실행하세요."
