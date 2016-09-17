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
  if [ -z "$DRUPAL_TI_CORE_BRANCH" ] || [ "$DRUPAL_TI_CORE_BRANCH" = "7.x" ];
  then
    #wget https://www.drupal.org/files/issues/2189345-39.patch
    wget https://gist.githubusercontent.com/legovaer/70bfcbed6cca026817fc5f22cceb9bec/raw/c52f687249d1d061488c66a6f53ed360e23f3679/add-autocoverage-7x.patch
    #git apply -v 2189345-39.patch
    git apply -v add-autocoverage-7x.patch
  fi

  if [ "$DRUPAL_TI_CORE_BRANCH" = "8.0.x" ];
  then
    wget https://gist.githubusercontent.com/legovaer/22c73d31ca32d1f172af47b15f29b7de/raw/550db3c7627479f807d07ab536f1ef4a517c7d22/add-autocoverage-80x.patch
    git apply -v add-autocoverage-80x.patch
  fi

  if [ "$DRUPAL_TI_CORE_BRANCH" = "8.1.x" ];
  then
    wget https://gist.githubusercontent.com/legovaer/352dfd62596a9bed7e39a8b849f62675/raw/826a265d56171608e4d1daf54487bd34957d98c8/add-autocoverage-81x.patch
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

  #rm -rf "$DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME"
  if [ $DRUPAL_TI_ANALYSE_CORE == 0 ]; then
    # Make sure that we aren't using a symbolic link of the module.
    mv "$TRAVIS_BUILD_DIR/$DRUPAL_TI_MODULE_NAME" "$DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH"
  else
    drush en $DRUPAL_TI_MODULE_NAME -y
  fi
  ls $DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH
}

function drupal_ti_coverage_prepare() {
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE" != "1" ] ; then return ; fi

  # Load environment variables
  drupal_ti_simpletest_coverage_vars

  drupal_ti_ensure_apt_get
  (
    cd $DRUPAL_TI_DIST_DIR
    wget http://ftp.us.debian.org/debian/pool/main/x/xdebug/php5-xdebug_2.2.5-1_amd64.deb
    dpkg -x php5-xdebug_2.2.5-1_amd64.deb .
  )
}

function drupal_ti_simpletest_coverage_start() {
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE" != "1" ] ; then return ; fi
  echo "Pwd before start"
  pwd
  phpcovrunner start
}

function drupal_ti_simpletest_coverage_report() {
  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE" != "1" ] ; then return ; fi

  # Load environment variables
  drupal_ti_simpletest_coverage_vars

  cd $DRUPAL_TI_DRUPAL_DIR

  match='<!DOCTYPE root ['
  if [ $DRUPAL_TI_ANALYSE_CORE == 1 ]; then
    insert="<!ENTITY path \"$DRUPAL_TI_DRUPAL_DIR/modules/$DRUPAL_TI_MODULE_NAME\">"
    echo "$DRUPAL_TI_DRUPAL_DIR/modules/$DRUPAL_TI_MODULE_NAME"
  else
    insert="<!ENTITY path \"$DRUPAL_TI_DRUPAL_DIR/$DRUPAL_TI_MODULES_PATH/$DRUPAL_TI_MODULE_NAME\">"
  fi
  sed -n -i "p;3a $insert" $DRUPAL_TI_SCRIPT_DIR/utility/phpcov.xml.dist

  phpcovrunner stop --html $DRUPAL_TI_DRUPAL_DIR/coverage-report \
  --configuration $DRUPAL_TI_SCRIPT_DIR/utility/phpcov.xml.dist

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
  drupal_ci_git_ensure_reports_branch $DRUPAL_TI_DESTINATION_BRANCH/$TRAVIS_BUILD_NUMBER

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
  echo "The simpletest coverage report can be found at https://rawgit.com/$TRAVIS_REPO_SLUG/$DRUPAL_TI_DESTINATION_BRANCH/$TRAVIS_BUILD_NUMBER/index.html"

  if [ "$DRUPAL_TI_SIMPLETEST_COVERAGE_GENERATE_BADGES" = "1" ]
  then
    echo "A code coverage badge has been generated:"
    echo "GitHub markup: [![Coverage](https://rawgit.com/$TRAVIS_REPO_SLUG/$DRUPAL_TI_DESTINATION_BRANCH/$TRAVIS_BUILD_NUMBER/badge.svg)](https://rawgit.com/$TRAVIS_REPO_SLUG/$DRUPAL_TI_DESTINATION_BRANCH/$TRAVIS_BUILD_NUMBER/index.html)"
    echo "Image URL: https://rawgit.com/$TRAVIS_REPO_SLUG/$DRUPAL_TI_DESTINATION_BRANCH/$TRAVIS_BUILD_NUMBER/badge.svg"
  fi
}

function drupal_ti_simpletest_coverage_vars() {
  export DRUPAL_TI_TMP_MODULE_PATH="$HOME/$DRUPAL_TI_MODULE_NAME"
}