#!/usr/bin/env bash
set -euo pipefail

w=/home/data/workspace/THOR-20261025-1341-NINFER
artifact="$w/artifacts/qwen3.8-coder-bf16hc-mtp.ninfer"
ngram="$w/artifacts/qwen3.8-coder-ngram.ninfer"
bin="$w/build/apps/ninfer-multicall"
side="$w/artifacts/hc-q8-sidecar"
template="$w/ninfer-all/tools/chat_templates/qwen3_8.jinja"

THOR_HOST="${THOR_HOST:-0.0.0.0}"
THOR_PORT="${THOR_PORT:-18778}"
THOR_API_KEY="${THOR_API_KEY:-sk-thor-local-change-me}"

if [ "$THOR_API_KEY" = "sk-thor-local-change-me" ]; then
  echo "WARNING: using the default placeholder API key; override THOR_API_KEY before exposing this service." >&2
fi

if [ ! "$(findmnt -n -o UUID --target /home/data)" = "2dc04d80-5f91-4c8c-be61-2bf4558756be" ]; then
  echo "ERROR: /home/data is not the expected data LV." >&2
  exit 1
fi

for f in "$artifact" "$ngram" "$bin" "$side/manifest.json" "$side/weights.q8_0" "$template"; do
  if [ ! -e "$f" ]; then
    echo "ERROR: missing file: $f" >&2
    exit 1
  fi
done

if ss -ltn | grep -q ":$THOR_PORT "; then
  echo "ERROR: port $THOR_PORT is already in use." >&2
  exit 1
fi

cd "$w"
. ./env.sh
export LD_LIBRARY_PATH="$w/sysroot/usr/lib/aarch64-linux-gnu:$w/sysroot/lib/aarch64-linux-gnu:${LD_LIBRARY_PATH:-}"
export NINFER_GGUF_Q6K_CUBLAS_PREFILL=1
export NINFER_THOR_QSA_AOT=1
export NINFER_GGUF_Q6K_COOPERATIVE=1
export NINFER_THOR_FA2_PREFIX=1
export NINFER_THOR_FA2_SPARSE=1
export NINFER_GGUF_DENSE_BF16_CUBLAS_PREFILL=1
export NINFER_QWEN4_PREFILL_8K=1
export NINFER_SM110_IQ4NL_OCC2=1
export NINFER_SM110_IQ2S_OCC2=1
export NINFER_SM110_IQ3_XXS_OCC2=1
export NINFER_SM110_IQ3_S_OCC2=1
export NINFER_THOR_IQ4NL_ROWOWNED=1
export NINFER_THOR_Q6K_PADDED_T1=0
export NINFER_SM110_IQ2S_BF16_PAIR=1
export NINFER_HC_Q8_SIDECAR="$side"
export NINFER_THOR_IQ4NL_T1_SLOT_PARALLEL=1

ulimit -c 0

exec "$bin" ninfer-serve "$artifact" \
  --host "$THOR_HOST" \
  --port "$THOR_PORT" \
  --api-key "$THOR_API_KEY" \
  --model-id qwen3.8-flash-next-coder-mtp-512k \
  --max-concurrency 1 \
  --max-context 524288 \
  --kv-capacity 524288 \
  --kv-dtype rk8v4 \
  --rope-yarn \
  --kv-resident all \
  --host-cache-mib 0 \
  --prefill-chunk 8192 \
  --device-profile off \
  --expert-residency device \
  --expert-cache-mib 0 \
  --ngram-table "$ngram" \
  --ngram-residency disk \
  --ngram-io mmap \
  --ngram-ram-mib 0 \
  --ngram-io-depth 64 \
  --chat-template "$template" \
  --spec mtp \
  --draft-tokens 3 \
  --draft-min-p 0 \
  --ngram-draft-tokens 0 \
  --default-reasoning-effort xhigh \
  --no-prefill-a8 \
  --log-stats-interval-ms 0 \
  --log-colours off
