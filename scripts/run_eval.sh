#!/usr/bin/env bash
# Backward compatibility redirect to repo root reproduce.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/../reproduce.sh" "$@"
