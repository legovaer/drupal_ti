<?php
/**
 * @file
 * Contains
 */

getenv("DRUPAL_TI_SIMPLETEST_FILE");
exec('{ php "$DRUPAL_TI_SIMPLETEST_FILE" --php $(which php) "${ARGS[@]}" || echo "1 fails"; } | tee /tmp/simpletest-result.txt');
