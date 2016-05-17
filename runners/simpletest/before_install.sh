#!/bin/bash

set -e $DRUPAL_TI_DEBUG

# Check wether code coverage is in scope
drupal_ti_simpletest_coverage_in_scope

# Ensure that the code coverage tools are installed.
drupal_ti_ensure_simpletest_coverage_tools