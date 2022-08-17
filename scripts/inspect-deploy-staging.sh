#!/bin/bash
# Tests that the deploy directory is consistent with itself
# Expects that each file and archive has a hash and that the hashes are good
set -euo pipefail

cd deploy
readonly HASH_COUNT=$(find . -name '*.sha256sum.txt' -exec cat {} \; | wc -l)
readonly ZIP_COUNT=$(find . -name '*.zip' | wc -l)
readonly TAR_COUNT=$(find . -name '*.tar.gz' | wc -l)
find . -name '*.tar.gz' | xargs -I{} tar -xf {}
readonly EXTRACT_COUNT=$(find . -mindepth 2 -type f | wc -l)

# We don't inspect the contents of the zip archive because we only expect 1 and there should be a
# duplicate tar archive that is already extracted
if [[ $ZIP_COUNT -ne 1 ]]; then
	>&2 echo "Expected exactly 1 zip archive and found $ZIP_COUNT archives"
	exit 1
fi

ZIP_FILE=$(find . -name '*.zip')
readonly WIN_ZIP_CNT=$(unzip -lqq "$ZIP_FILE" | wc -l)
readonly WIN_TAR_CNT=$(tar -tf "$(sed 's/.zip/.tar.gz/' <<< "$ZIP_FILE")" | wc -l)
if [[ $WIN_TAR_CNT -ne $WIN_ZIP_CNT ]]; then
	>&2 echo "windows zip and tar archives have different file counts"
	exit 1
fi

readonly FILE_COUNT=$(($TAR_COUNT + $ZIP_COUNT + $EXTRACT_COUNT))
if [[ $FILE_COUNT -ne $HASH_COUNT ]]; then
	>&2 echo "hash count ($HASH_COUNT) and file count ($FILE_COUNT) do not match"
	exit 1
fi

find . -name '*.sha256sum.txt' -exec sha256sum -c {} \; 
