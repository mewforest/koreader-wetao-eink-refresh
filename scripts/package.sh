#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${1:-${repo_root}/dist}"
version="${2:-$(tr -d '[:space:]' < "${repo_root}/VERSION")}"

if [[ "${output_dir}" != /* ]]; then
    output_dir="${repo_root}/${output_dir}"
fi

mkdir -p "${output_dir}"
archive="${output_dir}/wetaoeinkrefresh.koplugin-${version}.zip"

(
    cd "${repo_root}"
    zip -X -q -r "${archive}" wetaoeinkrefresh.koplugin
)

entries="$(unzip -Z1 "${archive}")"
for required in \
    wetaoeinkrefresh.koplugin/_meta.lua \
    wetaoeinkrefresh.koplugin/main.lua \
    wetaoeinkrefresh.koplugin/wetaoepd.lua
do
    if ! grep -Fxq "${required}" <<<"${entries}"; then
        printf 'Missing required archive entry: %s\n' "${required}" >&2
        exit 1
    fi
done

archive_name="$(basename "${archive}")"
(
    cd "${output_dir}"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "${archive_name}" > "${archive_name}.sha256"
    else
        shasum -a 256 "${archive_name}" > "${archive_name}.sha256"
    fi
)

printf '%s\n' "${archive}"
