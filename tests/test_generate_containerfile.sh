#!/bin/bash
# =============================================================================
# Regression tests for scripts/generate-containerfile.sh
# =============================================================================
#
# Tests the find_latest_version() function to ensure POSIX-compliant find
# usage (no GNU-only -printf). See: https://github.com/opendatahub-io/base-containers/issues/143
#
# Usage:
#   bash tests/test_generate_containerfile.sh
#
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS=0
FAIL=0

assert_eq() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "${expected}" == "${actual}" ]]; then
        echo "  PASS: ${description}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${description}"
        echo "    expected: '${expected}'"
        echo "    actual:   '${actual}'"
        FAIL=$((FAIL + 1))
    fi
}

# Inline copy of find_latest_version matching the script's implementation.
# This tests the POSIX-compliant approach (-exec basename {} \;).
find_latest_version() {
    local type="$1"
    local exclude="${2:-}"
    local type_dir="${PROJECT_ROOT}/${type}"

    if [[ ! -d "${type_dir}" ]]; then
        return 1
    fi

    local latest
    if [[ -n "${exclude}" ]]; then
        latest=$(find "${type_dir}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; \
            | grep -v "^${exclude}$" | sort -V | tail -1) || true
    else
        latest=$(find "${type_dir}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; \
            | sort -V | tail -1) || true
    fi

    if [[ -z "${latest}" ]]; then
        return 1
    fi

    echo "${latest}"
}

echo "=== find_latest_version tests ==="

# Test 1: find latest cuda version
if result=$(find_latest_version "cuda"); then :; else result=""; fi
assert_eq "cuda latest version is 13.1" "13.1" "${result}"

# Test 2: find latest cuda version excluding 13.1
if result=$(find_latest_version "cuda" "13.1"); then :; else result=""; fi
assert_eq "cuda latest excluding 13.1 is 13.0" "13.0" "${result}"

# Test 3: find latest cuda version excluding 13.0
if result=$(find_latest_version "cuda" "13.0"); then :; else result=""; fi
assert_eq "cuda latest excluding 13.0 is 13.1" "13.1" "${result}"

# Test 4: find latest python version
if result=$(find_latest_version "python"); then :; else result=""; fi
assert_eq "python latest version is 3.12" "3.12" "${result}"

# Test 5: find latest python version excluding 3.12 (should return empty/fail)
if result=$(find_latest_version "python" "3.12"); then :; else result=""; fi
assert_eq "python latest excluding 3.12 is empty (only version)" "" "${result}"

# Test 6: nonexistent type returns empty
if result=$(find_latest_version "nonexistent"); then :; else result=""; fi
assert_eq "nonexistent type returns empty" "" "${result}"

# Test 7: verify no GNU-only -printf in the script (regression guard)
echo ""
echo "=== POSIX compliance checks ==="
if grep -q '\-printf' "${PROJECT_ROOT}/scripts/generate-containerfile.sh"; then
    echo "  FAIL: scripts/generate-containerfile.sh still contains -printf (GNU-only)"
    FAIL=$((FAIL + 1))
else
    echo "  PASS: scripts/generate-containerfile.sh does not use -printf"
    PASS=$((PASS + 1))
fi

# Summary
echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [[ ${FAIL} -gt 0 ]]; then
    exit 1
fi
