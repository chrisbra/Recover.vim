SCRIPT=plugin/recover.vim autoload/recover.vim
DOC=doc/recoverPlugin.txt
PLUGIN=recover

.PHONY: $(PLUGIN).vba README test

all: uninstall vimball install README

vimball: $(PLUGIN).vba

clean:
	rm -rf *.vba */*.orig *.~* .VimballRecord doc/tags test/*/ test/testfile test/.testfile.sw?

dist-clean: clean

install:
	vim -N -c':so %' -c':q!' ${PLUGIN}.vba

uninstall:
	vim -N -c':RmVimball' -c':q!' ${PLUGIN}.vba
	rm -f ${PLUGIN}.vba

undo:
	for i in */*.orig; do mv -f "$$i" "$${i%.*}"; done

recover.vba:
	rm -f recover.vba
	vim -N -c 'ru! vimballPlugin.vim' -c ':let g:vimball_home=getcwd()'  -c ':call append("0", ["plugin/recover.vim", "autoload/recover.vim", "doc/recoverPlugin.txt"])' -c '$$d' -c ':%MkVimball ${PLUGIN}' -c':q!'

README:
	cp -f $(DOC) README

recover:
	vim -N -c 'ru! vimballPlugin.vim' -c ':call append("0", ["autoload/recover.vim", "doc/recoverPlugin.txt", "plugin/recover.vim"])' -c '$$d' -c ':%MkVimball ${PLUGIN} .' -c':q!'
     
release: version all

version:
	perl -i.orig -pne 'if (/Version:/) {s/\.(\d)*/sprintf(".%d", 1+$$1)/e}' ${SCRIPT}
	perl -i -pne 'if (/GetLatestVimScripts:/) {s/(\d+)\s+:AutoInstall:/sprintf("%d :AutoInstall:", 1+$$1)/e}' ${SCRIPT}
	#perl -i -pne 'if (/Last Change:/) {s/\d+\.\d+\.\d\+$$/sprintf("%s", `date -R`)/e}' ${SCRIPT}
	perl -i -pne 'if (/Last Change:/) {s/(:\s+).*\n/sprintf(": %s", `date -R`)/e}' ${SCRIPT}
	perl -i.orig -pne 'if (/Version:/) {s/\.(\d)+.*\n/sprintf(".%d %s", 1+$$1, `date -R`)/e}' ${DOC}

test:
	cd test && ./run_test.sh
