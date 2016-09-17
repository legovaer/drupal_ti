#!/bin/bash
#
if [ $DRUPAL_TI_ANALYSE_CORE == 0 ]; then
  if [ -d $TRAVIS_BUILD_DIR/$DRUPAL_TI_MODULE_NAME/tests ]; then
    echo "Tests directory exists, opening.."
    cd $TRAVIS_BUILD_DIR/$DRUPAL_TI_MODULE_NAME/tests
  else
    echo "Tests directory did not exist"
  fi
fi
drupal_ti_coverage_prepare
