#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf dest
mkdir dest

if [ ! -f D2Stats.exe ]; then
	echo "D2Stats.exe is missing; compile before collecting assets." >&2
	exit 1
fi

cp D2Stats.exe dest
cp -R Sounds dest
