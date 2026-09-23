# /bin/bash
set -e

rm -rf dest
mkdir dest

if [ ! -f D2Stats.exe ]; then
	echo "D2Stats.exe missing"
	exit 1
fi
if [ ! -f D2Stats.Core.exe ]; then
	echo "D2Stats.Core.exe missing — build core/ before packaging"
	exit 1
fi

cp D2Stats.exe dest
cp D2Stats.Core.exe dest
cp -R Sounds dest
