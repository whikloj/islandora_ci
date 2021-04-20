#!/bin/bash

# Common checks to get run during the 'script' section in Travis.
OUTPUT=0

# Make OUTPUT equal return code if return code is not 0
function checkReturn {
  if [ $1 -ne 0 ]; then
    OUTPUT=$1
  fi
}

$SCRIPT_DIR/line_endings.sh $GITHUB_WORKSPACE/build_dir
checkReturn $?

phpcs --standard=Drupal --ignore=*.md,*-min.css,*.css --extensions=php,module,inc,install,test,profile,theme,css,info $GITHUB_WORKSPACE/build_dir
checkReturn $?

phpcs --standard=Drupal $GITHUB_WORKSPACE/build_dir/styles/css/custom.css
checkReturn $?

ls -alh $GITHUB_WORKSPACE/build_dir
phpcpd --suffix .theme,.module,.inc,.test,.php $GITHUB_WORKSPACE/build_dir
checkReturn $?

exit $OUTPUT
