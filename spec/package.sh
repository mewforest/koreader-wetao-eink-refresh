#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "${test_root}"' EXIT

bash "${repo_root}/scripts/package.sh" "${test_root}" "0.1.0-test"

archive="${test_root}/wetaoeinkrefresh.koplugin-0.1.0-test.zip"
checksum="${archive}.sha256"

test -f "${archive}"
test -f "${checksum}"

entries="$(unzip -Z1 "${archive}")"
for required in \
    wetaoeinkrefresh.koplugin/_meta.lua \
    wetaoeinkrefresh.koplugin/main.lua \
    wetaoeinkrefresh.koplugin/wetaoepd.lua
do
    grep -Fxq "${required}" <<<"${entries}"
done

if command -v sha256sum >/dev/null 2>&1; then
    (cd "${test_root}" && sha256sum -c "$(basename "${checksum}")")
else
    (cd "${test_root}" && shasum -a 256 -c "$(basename "${checksum}")")
fi

printf 'PASS: release archive layout and checksum\n'
