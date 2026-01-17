#!/usr/bin/env bash
set -euo pipefail


ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Prefer an existing venv: VIRTUAL_ENV (active), VENV env var, or first arg
if [ -n "${VIRTUAL_ENV-}" ]; then
  VENV_DIR="$VIRTUAL_ENV"
elif [ -n "${VENV-}" ]; then
  VENV_DIR="$VENV"
elif [ -n "${1-}" ]; then
  VENV_DIR="$1"
else
  VENV_DIR="$ROOT_DIR/.venv"
fi

if [ ! -d "$VENV_DIR" ]; then
  echo "Creating venv at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi

echo "Using virtualenv: $VENV_DIR"
source "$VENV_DIR/bin/activate"

pip install --upgrade pip
pip install -r "$ROOT_DIR/requirements.txt"

pytest -q
