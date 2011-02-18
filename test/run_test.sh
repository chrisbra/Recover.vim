#!/bin/bash
set -x

for i in "a space" "a\\backslash"  "a
linebreak" "normal" "a'singlequote" 'a"doublequote' 'readonly'; do
    test -d "$i" && rm -rf "$i"
    mkdir "$i"
    cp recover.sh vimrc_recover "$i"
    pushd "$i"
    ./recover.sh
    # For readonly commands, this should not 
    # trigger SwapExists Autocommand
    if [ "$i" = 'readonly' ]; then
	echo "This buffer is readonly! The Autocommand SwapExists should not fire!">testfile
	chmod 0400 testfile
    fi
    popd
    reset
done
for i in "a space" "a\\backslash"  "a
linebreak" "normal" "a'singlequote" 'a"doublequote' 'readonly'; do
    pushd "$i"
    vim testfile
    popd
done
