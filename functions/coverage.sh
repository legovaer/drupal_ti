#!/bin/bash
# @file
# Common functionality for setting up simpletest code coverage

#
# Ensure that the code coverage tools are installed.
#
function drupal_ti_ensure_simpletest_coverage_tools() {
  # Load environment variables
  drupal_ti_simpletest_coverage_vars

  # Don't do anything if coverage is not in scope for this build.
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE_IN_SCOPE" = "0" ]; then return; fi

	# This function is re-entrant.
	if [ -r "$TRAVIS_BUILD_DIR/../drupal_ti-tools-for-simpletest-coverage-installed" ]
	then
		return
	fi

  cp -R $TRAVIS_BUILD_DIR $DRUPAL_TI_TMP_MODULE_PATH

  # In order to analyze the coverage, we need xdebug.
  drupal_ti_ensure_apt_get
  (
		cd $DRUPAL_TI_DIST_DIR
		wget http://ftp.us.debian.org/debian/pool/main/x/xdebug/php5-xdebug_2.2.5-1_amd64.deb
		dpkg -x php5-xdebug_2.2.5-1_amd64.deb .
	)

  # Download simpletest and include it in PHP.
  git clone https://github.com/simpletest/simpletest.git $DRUPAL_TI_SIMPLETEST_PATH
  #git clone https://github.com/sebastianbergmann/php-code-coverage.git $DRUPAL_TI_SIMPLETEST_PATH
  php $DRUPAL_TI_SCRIPT_DIR/utility/add_simpletest_to_include_path.php

  touch "$TRAVIS_BUILD_DIR/../drupal_ti-tools-for-simpletest-coverage-installed"
}

#
# Determines wether the simpletest coverage tool should be executed during this
# build.
#
function drupal_ti_simpletest_coverage_in_scope() {
  PHP_VERSION=$(phpenv version-name)
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE" = "1" ]
  then
    if [ "$PHP_VERSION" = "$DRUPAL_TI_SIMPLETEST_COVERAGE_PHP_VERSION" ]
    then
      export DRUPAL_TI_SIMPLETEST_COVERAGE_IN_SCOPE="1"
      return
    fi
  fi
  export DRUPAL_TI_SIMPLETEST_COVERAGE_IN_SCOPE="0"
}

#
# We need to copy the module to the module folder.
#
function drupal_ti_simpletest_coverage_install_module() {
  # Load environment variables
  drupal_ti_simpletest_coverage_vars

  # Don't do anything if coverage is not in scope for this build.
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE_IN_SCOPE" = "0" ]; then return; fi

  drush pm-uninstall $DRUPAL_TI_MODULE_NAME -y
  echo "CPing $DRUPAL_TI_TMP_MODULE_PATH to $DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME"
  rm -rf "$DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME"
  cp -R "$DRUPAL_TI_TMP_MODULE_PATH" "$DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME"
  drush en $DRUPAL_TI_MODULE_NAME -y
}

#
# Start analyzing the simpletest coverage
#
function drupal_ti_simpletest_coverage_start() {
  # Load environment variables
  drupal_ti_simpletest_coverage_vars

  # Don't do anything if coverage is not in scope for this build.
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE_IN_SCOPE" = "0" ]; then return; fi

  # Re-install the module to make sure it's in the right place.
  drupal_ti_simpletest_coverage_install_module

  # Create the code coverage data file and make it executable.
  cd "$DRUPAL_TI_DRUPAL_DIR"
  touch "code-coverage-settings.dat"
  chmod +x "code-coverage-settings.dat"

  # When using run-tests.sh with Gitlab CI it doesn't know there were failures
  # because the script always exits with at status of 0.
  # @see https://www.drupal.org/node/2189345
  wget https://www.drupal.org/files/issues/2189345-39.patch
  git apply -v 2189345-39.patch

  # When executing run-tests.sh we need to include the autocoverage file.
  git apply -v $DRUPAL_TI_SCRIPT_DIR/lib/include-simpletest-in-script.patch

  cd "$DRUPAL_TI_DRUPAL_DIR"
  # Start analyzing the simpletest coverage
  php $DRUPAL_TI_SIMPLETEST_PATH/extensions/coverage/bin/php-coverage-open.php
  #'--include=$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME/.*\.php$'
#    '--include=$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME/.*\.inc$' \
#    '--include=$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME/.*\.module$' \
#    '--exclude=$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME/tests/.*'

}

function drupal_ti_simpletest_coverage_report() {
  # Load environment variables
  drupal_ti_simpletest_coverage_vars

  # Don't do anything if coverage is not in scope for this build.
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE_IN_SCOPE" = "0" ]; then return; fi

  # DRUPAL_TI_SIMPLETEST_COVERAGE_GENERATE_BADGES
  cd "$DRUPAL_TI_DRUPAL_DIR"

  # Stop the coveragy analyzer tool.
  php $DRUPAL_TI_SIMPLETEST_PATH/extensions/coverage/bin/php-coverage-close.php

  # Ensure that the reports branch exists.
  git clone https://github.com/$TRAVIS_REPO_SLUG.git coverage-report
  cd coverage-report/
  drupal_ci_git_add_credentials
  drupal_ci_git_ensure_reports_branch $TRAVIS_BRANCH-reports

  # Clone the reports branch and delete all the old data.
  git checkout $TRAVIS_BRANCH-reports
  ls -ls
  find . ! -name '.git' ! -name '.' ! -name '..' -type d -exec rm -rf {} +
    ls -ls
  cd "$DRUPAL_TI_DRUPAL_DIR"
  ls -ls
  # Generate the code coverage report
  php $DRUPAL_TI_SIMPLETEST_PATH/extensions/coverage/bin/php-coverage-report.php
  cd coverage-report/
  ls -ls

  # Generate the code coverage badge if required.
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE_GENERATE_BADGES" = "1" ]
  then
    php "$DRUPAL_TI_SCRIPT_DIR/utility/generate_simpletest_coverage_badge.php"
  fi

  # Add, commit and push all report files.
  git add .
  git commit -m "Added report for $TRAVIS_JOB_NUMBER"
  git push -f
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
  export DRUPAL_TI_SIMPLETEST_PATH="$DRUPAL_TI_SCRIPT_DIR/lib/simpletest"
  export DRUPAL_TI_TMP_MODULE_PATH="$HOME/$DRUPAL_TI_MODULE_NAME"
  drupal_ti_simpletest_coverage_in_scope
}