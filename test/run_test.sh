#!/bin/sh

for i in "a space" "a\\backslash"  "a
linebreak" "normal" "a'singlequote" 'a"doublequote'; do
    test -d "$i" && rm -rf "$i"
    mkdir "$i"
    cp recover.sh vimrc_recover "$i"
    pushd "$i"
    ./recover.sh
    popd
    reset
done
for i in "a space" "a\\backslash"  "a
linebreak" "normal" "a'singlequote" 'a"doublequote'; do
    pushd "$i"
    vim testfile
    popd
done
