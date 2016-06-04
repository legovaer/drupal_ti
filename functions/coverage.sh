#!/bin/bash
# @file
# Common functionality for setting up simpletest code coverage

#
# Ensure that phpcov is installed.
#
function drupal_ti_ensure_phpcov() {
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE" != "1" ] ; then return ; fi

  # This function is re-entrant.
  if [ -r "$TRAVIS_BUILD_DIR/../drupal_ti-phpcov-installed" ]
  then
    return
  fi

  composer global require legovaer/phpcov-runner=dev-master

  cd "$DRUPAL_TI_DRUPAL_DIR"
  echo "CORE BRANCH: $DRUPAL_TI_CORE_BRANCH"
  if [ -z "$DRUPAL_TI_CORE_BRANCH" ] || [ "$DRUPAL_TI_CORE_BRANCH" = "7.x" ];
  then
    wget https://www.drupal.org/files/issues/2189345-39.patch
    wget https://gist.githubusercontent.com/legovaer/70bfcbed6cca026817fc5f22cceb9bec/raw/9d54a0842fabcc9f1b2f1ebb53cf3e05013736a6/add-autocoverage-7x.patch
    git apply -v 2189345-39.patch
    git apply -v add-autocoverage-7x.patch
  fi

  if [ "$DRUPAL_TI_CORE_BRANCH" = "8.0.x" ];
  then
    wget https://gist.githubusercontent.com/legovaer/c9008fc282058a06924869eab8c19020/raw/38ef7c752da57eebd52fd6d4f864a4c4df517eb8/fix-simpletest-d8.patch
    git apply -v add-autocoverage-80x.patch
  fi

  if [ "$DRUPAL_TI_CORE_BRANCH" = "8.1.x" ];
  then
    wget https://gist.githubusercontent.com/legovaer/6e3bd63340cb48eed4e556303b5b97b9/raw/8f0a3abf95c91d552807351e8b1bdeca8017c48b/fix-simpletest-d81.patch
    git apply -v add-autocoverage-81x.patch
  fi

  touch "$TRAVIS_BUILD_DIR/../drupal_ti-phpcov-installed"
}

#
# We need to copy the module to the module folder.
#
function drupal_ti_simpletest_coverage_install_module() {
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE" != "1" ] ; then return ; fi

  # Load environment variables
  drupal_ti_simpletest_coverage_vars

  drush pm-uninstall $DRUPAL_TI_MODULE_NAME -y
  rm -rf "$DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME"
  cp -R "$DRUPAL_TI_TMP_MODULE_PATH" "$DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME"
  drush en $DRUPAL_TI_MODULE_NAME -y
}

function drupal_ti_coverage_prepare() {
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE" != "1" ] ; then return ; fi

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

function drupal_ti_simpletest_coverage_start() {
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE" != "1" ] ; then return ; fi

  phpcovrunner start
}

function drupal_ti_simpletest_coverage_report() {
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE" != "1" ] ; then return ; fi

  # Load environment variables
  drupal_ti_simpletest_coverage_vars

  phpcovrunner stop --html $DRUPAL_TI_DRUPAL_DIR/coverage-report \
  --configuration $DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME/phpcov.xml.dist

  # DRUPAL_TI_SIMPLETEST_COVERAGE_GENERATE_BADGES
  cd "$DRUPAL_TI_DRUPAL_DIR"

  # Ensure that the reports branch exists.
  if [ ! -d "coverage-report/" ]; then
    return
  fi
  cp /tmp/coverage.sqlite coverage-report/
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
  git commit -m "Added report for $TRAVIS_JOB_NUMBER"
  git push --set-upstream origin $BRANCH
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