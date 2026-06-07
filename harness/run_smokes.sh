#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$ROOT/harness/smoke_verify.sh"
bash "$ROOT/harness/smoke_backlog.sh"
printf 'SMOKE 16 GREEN\n'
