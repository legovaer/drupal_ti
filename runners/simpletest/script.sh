#!/bin/bash
# @file
# Simple script to run the tests via travis-ci.

set -e $DRUPAL_TI_DEBUG

# Load coverage variables.
drupal_ti_simpletest_coverage_vars
echo "Got $DRUPAL_TI_SIMPLETEST_PATH"

export ARGS=( $DRUPAL_TI_SIMPLETEST_ARGS )

if [ -n "$DRUPAL_TI_SIMPLETEST_GROUP" ]
then
        ARGS=( "${ARGS[@]}" "$DRUPAL_TI_SIMPLETEST_GROUP" )
fi


cd "$DRUPAL_TI_DRUPAL_DIR"
{ php "$DRUPAL_TI_SIMPLETEST_FILE" --php $(which php) "${ARGS[@]}" || echo "1 fails"; } | tee /tmp/simpletest-result.txt
cat $DRUPAL_TI_SIMPLETEST_FILE
egrep -i "([1-9]+ fail[s]?\s)|(Fatal error)|([1-9]+ exception[s]?\s)" /tmp/simpletest-result.txt && exit 1
exit 0
