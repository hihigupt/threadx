#! /bin/bash

set -o errexit # Exit if command failed.
set -o nounset # Exit if variable not set.
set -o pipefail # Exit if pipe failed.

SCRIPT_DIR=`dirname "$0"`

renode $SCRIPT_DIR/riscv.resc
