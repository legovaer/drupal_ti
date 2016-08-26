#!/bin/bash
#
if [ -d $TRAVIS_BUILD_DIR/$DRUPAL_TI_MODULE_NAME/tests ]; then
  echo "Tests directory exists, opening.."
  cd $TRAVIS_BUILD_DIR/$DRUPAL_TI_MODULE_NAME/tests
else
  echo "Tests directory did not exist"
fi

drupal_ti_coverage_prepare
