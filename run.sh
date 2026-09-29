#!/usr/bin/env bash
# 매번: Ollama와 모델을 확인하고 서버를 켠다. http://127.0.0.1:8000
#   ITDA_DB=demo.db ./run.sh    # 다른 DB 파일로 실행 (backend/ 기준 경로)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

[ -x .venv/bin/python ] || { echo "먼저 ./setup.sh 를 실행하세요." >&2; exit 1; }

if ! ollama list >/dev/null 2>&1; then
  echo "Ollama 서버를 시작합니다 (로그: ollama.log)"
  nohup ollama serve >ollama.log 2>&1 &
  for _ in $(seq 30); do ollama list >/dev/null 2>&1 && break; sleep 1; done
  ollama list >/dev/null 2>&1 || { echo "Ollama 서버가 응답하지 않습니다." >&2; exit 1; }
fi

MODEL="$(.venv/bin/python -c "import yaml; print(yaml.safe_load(open('backend/config/settings.yaml'))['model_name'])")"
ollama show "$MODEL" >/dev/null 2>&1 \
  || { echo "모델 '$MODEL' 이 등록되지 않았습니다. ./setup.sh 를 다시 실행하세요." >&2; exit 1; }

echo "잇다 서버 시작: http://127.0.0.1:8000  (종료: Ctrl+C)"
cd backend
exec ../.venv/bin/python -m app
