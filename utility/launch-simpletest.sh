#!/bin/bash
{ php "$DRUPAL_TI_SIMPLETEST_FILE" --php $(which php) "${ARGS[@]}" || echo "1 fails"; } | tee /tmp/simpletest-result.txt
cat $DRUPAL_TI_SIMPLETEST_FILE
egrep -i "([1-9]+ fail[s]?\s)|(Fatal error)|([1-9]+ exception[s]?\s)" /tmp/simpletest-result.txt && exit 1