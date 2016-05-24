#!/bin/bash
# Stop the coverage analyzer and generate the report.
php $DRUPAL_TI_SCRIPT_DIR/utility/stop_php_code_coverage.php
#drupal_ti_simpletest_coverage_report;
ls -ls /tmp/code-coverage-report