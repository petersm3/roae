#!/bin/bash
# capture_build_manifest.sh — emit a build-environment manifest for a canonical's metadata.txt
#
# Usage:
#   cd <repo-root>
#   bash scripts/capture_build_manifest.sh > manifest_block.txt
#
# Then cat this output into the canonical run's metadata.txt before sha + record-count fields.
#
# Captures: source identity (commit + sha of solve.c), toolchain (gcc, glibc, libgomp),
# host (kernel, CPU model + flags), and OS image (distro, Azure image SKU if available).
#
# See DEVELOPMENT.md §"Build reproducibility — toolchain manifest and cross-build verification"
# for the rationale and the cross-build regression gate this feeds.

set -e

echo "=== source ==="
if git rev-parse HEAD > /dev/null 2>&1; then
    echo "solve.c commit:    $(git rev-parse HEAD)"
    echo "solve.c branch:    $(git rev-parse --abbrev-ref HEAD)"
    [ -n "$(git status --porcelain solve.c 2>/dev/null)" ] && echo "WARNING: solve.c has uncommitted local changes"
fi
[ -r solve.c ] && echo "solve.c sha256:    $(sha256sum solve.c | cut -d' ' -f1)"
echo

echo "=== toolchain ==="
gcc --version | head -1
ldd --version | head -1
GOMP_PATH=$(gcc -print-prog-name=libgomp.so.1 2>/dev/null)
echo "libgomp path:      ${GOMP_PATH:-unknown}"
if [ -L "$GOMP_PATH" ]; then
    echo "libgomp resolved:  $(readlink -f $GOMP_PATH)"
fi
echo

echo "=== host ==="
uname -srvmpio
# F09-A04#7: x86 /proc/cpuinfo names the CPU in `model name` and lists `flags`; AArch64 names it by
# `CPU implementer` / `CPU architecture` / `CPU part` and lists `Features`. Report whichever is there,
# and "n/a" rather than an empty field.
CPU_MODEL="$(grep -m1 '^model name' /proc/cpuinfo | sed 's/^.*: //' || true)"
if [ -z "$CPU_MODEL" ]; then
    _impl="$(grep -m1 '^CPU implementer' /proc/cpuinfo | sed 's/^.*: //' || true)"
    _arch="$(grep -m1 '^CPU architecture' /proc/cpuinfo | sed 's/^.*: //' || true)"
    _part="$(grep -m1 '^CPU part' /proc/cpuinfo | sed 's/^.*: //' || true)"
    if [ -n "$_impl$_part" ]; then CPU_MODEL="implementer=${_impl:-n/a} architecture=${_arch:-n/a} part=${_part:-n/a}"; fi
fi
echo "CPU model:         ${CPU_MODEL:-n/a}"
echo "CPU cores:         $(grep -c ^processor /proc/cpuinfo || true)"
if grep -q '^flags' /proc/cpuinfo; then
    CPU_FLAGS="$(grep -m1 '^flags' /proc/cpuinfo | tr ' ' '\n' | grep -E '^(avx|avx2|avx512|sse4_2|fma|bmi1|bmi2|popcnt)$' | tr '\n' ' ' || true)"
elif grep -q '^Features' /proc/cpuinfo; then
    CPU_FLAGS="$(grep -m1 '^Features' /proc/cpuinfo | sed 's/^.*: //' | tr ' ' '\n' | grep -E '^(asimd|sve|sve2|aes|pmull|sha2|crc32|atomics|popcnt)$' | tr '\n' ' ' || true)"
fi
echo "CPU flags subset:  ${CPU_FLAGS:-n/a}"
echo "RAM:               $(grep MemTotal /proc/meminfo | awk '{print $2/1024/1024 " GiB"}')"
echo

echo "=== os image ==="
if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo "Distro:            $NAME $VERSION_ID ($VERSION_CODENAME)"
fi
# Azure image SKU + image build date (when on Azure VMs)
if [ -r /etc/cloud/build.info ]; then
    echo "Azure image info:"
    sed 's/^/                   /' /etc/cloud/build.info
elif command -v curl > /dev/null 2>&1; then
    # Best-effort fetch from IMDS (Azure Instance Metadata Service) if reachable
    # F09-A02#14 / F09-A04#8: best-effort means best-effort -- under `set -e` an unreachable endpoint
    # (curl rc 28 on a non-Azure host) used to abort the whole manifest.
    IMDS=$(curl -s -m 2 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" 2>/dev/null) || IMDS=""
    if [ -n "$IMDS" ]; then
        SKU=$(echo "$IMDS" | grep -oP '"vmSize":"[^"]+' | head -1 | cut -d'"' -f4)
        IMG=$(echo "$IMDS" | grep -oP '"sku":"[^"]+' | head -1 | cut -d'"' -f4)
        VER=$(echo "$IMDS" | grep -oP '"version":"[^"]+' | head -1 | cut -d'"' -f4)
        [ -n "$SKU" ] && echo "Azure VM size:     $SKU"
        [ -n "$IMG" ] && echo "Azure image SKU:   $IMG"
        [ -n "$VER" ] && echo "Azure image ver:   $VER"
    fi
fi
echo

echo "=== build artifact (post-compile, if solve binary present in cwd) ==="
if [ -x ./solve ]; then
    echo "solve binary sha:  $(sha256sum ./solve | cut -d' ' -f1)"
    echo "solve binary size: $(stat -c%s ./solve) bytes"
    file ./solve | sed 's/^.*: /file:              /'
fi
