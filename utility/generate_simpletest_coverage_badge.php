<?php
/**
 * @file
 * Script that will create and download a shields.io badge.
 */
$file = "./index.html";
$doc = new DOMDocument();
$doc->loadHTMLFile($file);

$xpath = new DOMXpath($doc);

$elements = $xpath->query("//span[contains(@class, \"totalPercentCoverage\")]");

$percent = NULL;
if (!is_null($elements)) {
  foreach ($elements as $element) {
    $nodes = $element->childNodes;
    foreach ($nodes as $node) {
      $percent = $node->nodeValue;;
    }
  }
}


if ($percent == NULL) {
  $url = "https://img.shields.io/badge/coverage-fail-lightgrey.svg";
}
else {
  if ($percent <= 17) $color = "red";
  elseif ($percent <= 34) $color = "orange";
  elseif ($percent <= 41) $color = "yellow";
  elseif ($percent <= 58) $color = "yellowgreen";
  elseif ($percent <= 75) $color = "green";
  else $color = "brightgreen";

  $url = "https://img.shields.io/badge/coverage-$percent-$color.svg";
}

# Download and rename the badge.
exec("curl -O https://img.shields.io/badge/coverage-$percent-$color.svg");
exec("mv coverage-$percent-$color.svg badge.svg");
