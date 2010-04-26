#!/bin/sh

# Starts an editing session with vim and kills vim later hard.
# this can be used to test, whether the recoverPlugin works correctly
f=./testfile
rm -f .testfile.sw?
printf "not saved\n">$f
vim -u NONE -N -S vimrc_recover $f & 
sleep 3
kill -KILL $!
#cat $f
