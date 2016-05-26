#!/bin/bash
# @file
# Simple script to run the tests via travis-ci.

set -e $DRUPAL_TI_DEBUG

export ARGS=( $DRUPAL_TI_SIMPLETEST_ARGS )

if [ -n "$DRUPAL_TI_SIMPLETEST_GROUP" ]
then
        ARGS=( "${ARGS[@]}" "$DRUPAL_TI_SIMPLETEST_GROUP" )
fi


cd "$DRUPAL_TI_DRUPAL_DIR"
phpcov execute $DRUPAL_TI_SCRIPT_DIR/utility/launch-simpletest.sh bash \
  --configuration $DRUPAL_TI_MODULES_PATH/scheduler/$DRUPAL_TI_PHPCOV_XML \
  --html $DRUPAL_TI_DRUPAL_DIR/coverage-report
exit 0
