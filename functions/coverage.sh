#!/bin/bash
# @file
# Common functionality for setting up simpletest code coverage

#
# Ensure that phpcov is installed.
#
function drupal_ti_ensure_phpcov() {
  # This function is re-entrant.
  if [ -r "$TRAVIS_BUILD_DIR/../drupal_ti-phpcov-installed" ]
  then
    return
  fi

  composer global require 'phpunit/phpcov=*'
  touch "$TRAVIS_BUILD_DIR/../drupal_ti-phpcov-installed"
}

#
# We need to copy the module to the module folder.
#
function drupal_ti_simpletest_coverage_install_module() {
  # Load environment variables
  drupal_ti_simpletest_coverage_vars

  drush pm-uninstall $DRUPAL_TI_MODULE_NAME -y
  echo "CPing $DRUPAL_TI_TMP_MODULE_PATH to $DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME"
  rm -rf "$DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME"
  cp -R "$DRUPAL_TI_TMP_MODULE_PATH" "$DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME"
  drush en $DRUPAL_TI_MODULE_NAME -y
}

function drupal_ti_coverage_prepare() {
  # Load environment variables
  drupal_ti_simpletest_coverage_vars
  cp -R $TRAVIS_BUILD_DIR $DRUPAL_TI_TMP_MODULE_PATH

  drupal_ti_ensure_apt_get
  (
    cd $DRUPAL_TI_DIST_DIR
    wget http://ftp.us.debian.org/debian/pool/main/x/xdebug/php5-xdebug_2.2.5-1_amd64.deb
    dpkg -x php5-xdebug_2.2.5-1_amd64.deb .
  )
}

function drupal_ti_simpletest_coverage_report() {
  # Load environment variables
  drupal_ti_simpletest_coverage_vars

  # DRUPAL_TI_SIMPLETEST_COVERAGE_GENERATE_BADGES
  cd "$DRUPAL_TI_DRUPAL_DIR"

  # Ensure that the reports branch exists.
  cd coverage-report/
  git init
  git remote add origin https://github.com/$TRAVIS_REPO_SLUG.git
  drupal_ci_git_add_credentials
  drupal_ci_git_ensure_reports_branch $TRAVIS_BRANCH-reports

  # Clone the reports branch and delete all the old data.
  ls -ls

  # Generate the code coverage badge if required.
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE_GENERATE_BADGES" = "1" ]
  then
    php "$DRUPAL_TI_SCRIPT_DIR/utility/generate_simpletest_coverage_badge.php"
  fi

  # Add, commit and push all report files.
  git add *
  git checkout $TRAVIS_BRANCH-reports
  git commit -m "Added report for $TRAVIS_JOB_NUMBER"
  git push
  git tag $TRAVIS_JOB_NUMBER
  git push --tags

  echo "SIMPLETEST CODE COVERAGE COMPLETED!"
  echo "The simpletest coverage report can be found at https://rawgit.com/$TRAVIS_REPO_SLUG/$TRAVIS_BRANCH-reports/index.html"

  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE_GENERATE_BADGES" = "1" ]
  then
    echo "A code coverage badge has been generated:"
    echo "GitHub markup: [![Coverage](https://rawgit.com/$TRAVIS_REPO_SLUG/$TRAVIS_BRANCH-reports/badge.svg)](https://rawgit.com/$TRAVIS_REPO_SLUG/$TRAVIS_BRANCH-reports/index.html)"
    echo "Image URL: https://rawgit.com/$TRAVIS_REPO_SLUG/$TRAVIS_BRANCH-reports/badge.svg"
  fi
}

function drupal_ti_simpletest_coverage_vars() {
  export DRUPAL_TI_TMP_MODULE_PATH="$HOME/$DRUPAL_TI_MODULE_NAME"
}