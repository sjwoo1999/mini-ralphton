#!/usr/bin/env bash
set -euo pipefail

command -v bash >/dev/null || { printf 'bash is required\n' >&2; exit 1; }
command -v node >/dev/null || { printf 'node is required\n' >&2; exit 1; }
command -v npm >/dev/null || { printf 'npm is required\n' >&2; exit 1; }

if test ! -d node_modules; then
  npm install
fi

bash harness/run_smokes.sh
bash harness/verify.sh
printf 'INSTALL GREEN\n'
