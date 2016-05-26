#!/bin/bash
# @file
# Simple script to run the tests via travis-ci.

cd "$DRUPAL_TI_DRUPAL_DIR"

ls -ls $DRUPAL_TI_MODULES_PATH

phpcov execute $DRUPAL_TI_SIMPLETEST_FILE bash --arguments "--php $(which php) $DRUPAL_TI_SIMPLETEST_GROUP"
#phpcov execute $DRUPAL_TI_SCRIPT_DIR/utility/launch-simpletest.sh bash \
#  --configuration $DRUPAL_TI_MODULES_PATH/scheduler/$DRUPAL_TI_PHPCOV_XML \
  --html $DRUPAL_TI_DRUPAL_DIR/coverage-report
exit 0
