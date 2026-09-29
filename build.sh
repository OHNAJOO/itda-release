#!/usr/bin/env bash
# 개발자 PC용: itda-backend · itda-frontend · itda-model에서 빌드해 backend/ static/ model/을 채운다.
#   ./build.sh                  # 세 레포가 이 폴더 옆(../)에 있을 때
#   SKIP_GGUF=1 ./build.sh      # 큰 .gguf 복사는 건너뜀 (Modelfile만 갱신)
# 레포 위치가 다르면 BACKEND_REPO · FRONTEND_REPO · MODEL_REPO로 지정한다.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKEND_REPO="${BACKEND_REPO:-$ROOT/../itda-backend}"
FRONTEND_REPO="${FRONTEND_REPO:-$ROOT/../itda-frontend}"
MODEL_REPO="${MODEL_REPO:-$ROOT/../itda-model}"

for d in "$BACKEND_REPO" "$FRONTEND_REPO" "$MODEL_REPO"; do
  [ -d "$d" ] || { echo "레포를 찾을 수 없음: $d" >&2; exit 1; }
done

echo "==> backend  ($BACKEND_REPO)"
rm -rf "$ROOT/backend"
mkdir -p "$ROOT/backend"
cp -r "$BACKEND_REPO/app" "$BACKEND_REPO/config" "$BACKEND_REPO/demo" "$ROOT/backend/"
find "$ROOT/backend" -name __pycache__ -type d -prune -exec rm -rf {} +
(cd "$BACKEND_REPO" && uv export --no-dev --no-hashes --no-emit-project --no-header --format requirements-txt) \
  > "$ROOT/backend/requirements.txt"

echo "==> frontend ($FRONTEND_REPO)"
(cd "$FRONTEND_REPO" && pnpm install --frozen-lockfile && pnpm build)
rm -rf "$ROOT/static"
mkdir -p "$ROOT/static"
cp -r "$FRONTEND_REPO/dist/." "$ROOT/static/"

echo "==> model    ($MODEL_REPO)"
mkdir -p "$ROOT/model"
cp "$MODEL_REPO/Modelfile" "$ROOT/model/"
if [ -z "${SKIP_GGUF:-}" ]; then
  cp -u "$MODEL_REPO"/*.gguf "$ROOT/model/"   # 바뀐 경우에만 복사
fi

echo "완료. model/*.gguf 는 git에 올라가지 않으니 별도로 전달하세요."
