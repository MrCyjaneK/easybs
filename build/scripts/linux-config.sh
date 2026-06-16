#!/bin/bash
# Source the active Linux flavor config (set EASYBS_FLAVOR in the Dockerfile).
: "${EASYBS_FLAVOR:?EASYBS_FLAVOR must be set}"
source "/w/build/config.${EASYBS_FLAVOR}.sh"
