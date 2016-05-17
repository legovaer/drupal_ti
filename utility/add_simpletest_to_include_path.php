<?php
/**
 * @file
 * Adds simpletest to the include path.
 */
$path = getenv("DRUPAL_TI_SIMPLETEST_PATH") . '/extensions/coverage';
set_include_path(get_include_path() . PATH_SEPARATOR . $path);
