#!/usr/bin/env bash
# 개발자 PC용: itda-backend · itda-frontend · itda-model에서 빌드해 backend/ model/ wheels/를 채운다.
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

# 백엔드는 backend/static 에서 화면 파일을 찾는다. 링크 대신 복사해 Windows에서도 그대로 쓴다.
echo "==> frontend ($FRONTEND_REPO)"
(cd "$FRONTEND_REPO" && pnpm install --frozen-lockfile && pnpm build)
mkdir -p "$ROOT/backend/static"
cp -r "$FRONTEND_REPO/dist/." "$ROOT/backend/static/"

# Windows 설치기(itda-installer)가 인터넷 없이 pip install 하도록 패키지를 미리 받아 둔다.
echo "==> wheels   (win_amd64, Python 3.12)"
# pip은 환경 표식을 빌드 PC 기준으로 판단하므로 win32 제외 줄(uvloop)은 직접 뺀다.
rm -rf "$ROOT/wheels/win_amd64"
mkdir -p "$ROOT/wheels/win_amd64"
grep -v "sys_platform != 'win32'" "$ROOT/backend/requirements.txt" > "$ROOT/wheels/win_amd64/requirements.txt"
uvx pip download -q -r "$ROOT/wheels/win_amd64/requirements.txt" -d "$ROOT/wheels/win_amd64" \
  --platform win_amd64 --python-version 3.12 --implementation cp --only-binary=:all:

echo "==> model    ($MODEL_REPO)"
mkdir -p "$ROOT/model"
cp "$MODEL_REPO/Modelfile" "$ROOT/model/"
if [ -z "${SKIP_GGUF:-}" ]; then
  cp -u "$MODEL_REPO"/*.gguf "$ROOT/model/"   # 바뀐 경우에만 복사
fi

echo "완료. model/*.gguf 는 git에 올라가지 않으니 별도로 전달하세요."
