#!/bin/sh
f=./testfile
rm -f $f
#vim +'set ut=100' $'+normal inot saved\e:w\n0dw\e:exe ":!sleep 2;kill -KILL ".getpid()\n'
#vim +'set ut=100' $'+normal inot saved\e:w\n0dw' -c ":sleep 2" -c ":exe ':!kill -KILL '.getpid()" $f
vim +'set ut=100' $'+normal inot saved\e:w\n0dw' -c ":echo ':!kill -KILL '.getpid()" $f
#vim $f
cat $f

