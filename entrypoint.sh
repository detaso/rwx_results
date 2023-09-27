#!/bin/bash

set -euo pipefail

export PATH="/app/exe:$PATH"

if [ "$1" != "rwx_results" ] && [ "$1" != "bash" ]; then
	set -- rwx_results "$@"
fi

exec "$@"
