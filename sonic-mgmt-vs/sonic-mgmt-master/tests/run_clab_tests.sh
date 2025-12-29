#!/bin/bash
# Test runner for SONiC-VS Containerlab topology
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTBED_FILE="${SCRIPT_DIR}/clab_testbed.csv"
TESTBED_NAME="clab-sonic-vs-t0"
INVENTORY="${SCRIPT_DIR}/../ansible/clab_inventory"

TEST_PATH="${1:-.}"
shift || true

python3 -m pytest "$TEST_PATH" \
    --testbed="$TESTBED_NAME" \
    --testbed_file="$TESTBED_FILE" \
    --ansible-inventory="$INVENTORY" \
    --host-pattern="dut" \
    "$@"

