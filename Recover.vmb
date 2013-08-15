" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/recover.vim	[[[1
34
" Vim plugin for diffing when swap file was found
" Last Change: Wed, 14 Aug 2013 22:39:13 +0200
" Version: 0.18
" Author: Christian Brabandt <cb@256bit.org>
" Script:  http://www.vim.org/scripts/script.php?script_id=3068 
" License: VIM License
" GetLatestVimScripts: 3068 17 :AutoInstall: recover.vim
" Documentation: see :h recoverPlugin.txt

" ---------------------------------------------------------------------
" Load Once: {{{1
if exists("g:loaded_recover") || &cp
  finish
endif
let g:loaded_recover = 1"}}}
let s:keepcpo          = &cpo
set cpo&vim

" ---------------------------------------------------------------------
" Public Interface {{{1
" Define User-Commands and Autocommand "{{{
call recover#Recover(1)

com! RecoverPluginEnable :call recover#Recover(1)
com! RecoverPluginDisable :call recover#Recover(0)
com! RecoverPluginHelp   :call recover#Help()

" =====================================================================
" Restoration And Modelines: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo

" Modeline {{{1
" vim: fdm=marker sw=2 sts=2 ts=8 fdl=0
autoload/recover.vim	[[[1
435
" Vim plugin for diffing when swap file was found
" ---------------------------------------------------------------
" Author: Christian Brabandt <cb@256bit.org>
" Version: 0.18
" Last Change: Wed, 14 Aug 2013 22:39:13 +0200
" Script:  http://www.vim.org/scripts/script.php?script_id=3068
" License: VIM License
" GetLatestVimScripts: 3068 18 :AutoInstall: recover.vim
"
fu! recover#Recover(on) "{{{1
    if a:on
	call s:ModifySTL(1)
	if !exists("s:old_vsc")
	    let s:old_vsc = v:swapchoice
	endif
	augroup Swap
	    au!
	    au SwapExists * nested :call recover#ConfirmSwapDiff()
	    au BufWinEnter,InsertEnter,InsertLeave,FocusGained *
			\ call <sid>CheckSwapFileExists()
	augroup END
    else
	augroup Swap
	    au!
	augroup end
	if exists("s:old_vsc")
	    let v:swapchoice=s:old_vsc
	endif
    endif
endfu

fu! s:Swapname() "{{{1
    " Use sil! so a failing redir (e.g. recursive redir call)
    " won't hurt. (https://github.com/chrisbra/Recover.vim/pull/8)
    sil! redir => a |sil swapname|redir end
    if a[1:] == 'No swap file'
	return ''
    else
	return a[1:]
    endif
endfu

fu! s:CheckSwapFileExists() "{{{1
    if !&swapfile
	return
    endif

    let swap = s:Swapname()
    if !empty(swap) && !filereadable(swap)
	" previous SwapExists autocommand deleted our swapfile,
	" recreate it and avoid E325 Message
	call s:SetSwapfile()
    endif
endfu

fu! s:CheckRecover() "{{{1
    if exists("b:swapname") && !exists("b:did_recovery")
	let t = tempname()
	" Doing manual recovery, otherwise, BufRead autocmd seems to
	" get into the way of the recovery
	try
	    exe 'recover' fnameescape(expand('%:p'))
	catch /^Vim\%((\a\+)\)\=:E/
	    " Prevent any recovery error from disrupting the diff-split.
	endtry
	exe ':sil w' t
	call system('diff '. shellescape(expand('%:p'),1).
		    \ ' '. shellescape(t,1))
	call delete(t)
	if !v:shell_error
	    call inputsave()
	    redraw! " prevent overwriting of 'Select File to use for recovery dialog'
	    let p = confirm("No differences: Delete old swap file '".b:swapname."'?",
		    \ "&No\n&Yes", 2)
	    call inputrestore()
	    if p == 2
		" Workaround for E305 error
		let v:swapchoice=''
		call delete(b:swapname)
		" can trigger SwapExists autocommands again!
		call s:SetSwapfile()
	    endif
	    call recover#AutoCmdBRP(0)
	else
	    echo "Found Swapfile '". b:swapname. "', showing diff!"
	    call recover#DiffRecoveredFile()
	    " Not sure, why this needs feedkeys
	    " Sometimes cursor is wrong, I hate when this happens
	    " Cursor is wrong only when there is a single buffer open, a simple
	    " workaround for that is to check if bufnr('') is 1 and total number
	    " of windows in current tab is less than 3 (i.e. no windows were
	    " autoopen): in this case ':wincmd l\n:0\n' must be fed to
	    " feedkeys
	    if bufnr('') == 1 && winnr('$') < 3
		call feedkeys(":wincmd l\<cr>", 't')
	    endif
	    if !(v:version > 703 || (v:version == 703 && has("patch708")))
		call feedkeys(":0\<cr>", 't')
	    endif
	endif
	let b:did_recovery = 1
	if get(s:, 'fencview_autodetect', 0)
	    setl buftype=
	endif
	" Don't delete the auto command yet.
	"call recover#AutoCmdBRP(0)
    endif
endfun

fu! recover#ConfirmSwapDiff() "{{{1
    if exists("b:swapchoice")
	let v:swapchoice = b:swapchoice
	return
    endif
    let delete = 0
    let do_modification_check = exists("g:RecoverPlugin_Edit_Unmodified") ? g:RecoverPlugin_Edit_Unmodified : 0
    let not_modified = 0
    let msg = ""
    let bufname = s:isWin() ? fnamemodify(expand('%'), ':p:8') : shellescape(expand('%'))
    let tfile = tempname()
    if executable('vim') && !s:isWin()
	" Doesn't work on windows (system() won't be able to fetch the output)
	" Capture E325 Warning message
	" Leave English output, so parsing will be easier
	" TODO: make it work on windows.
	if s:isWin()
	  let wincmd = printf('-c "redir > %s|1d|:q!" ', tfile)
	  let wincmd = printf('-c "call feedkeys(\"o\n\e:q!\n\")"')
	endif
	let cmd = printf("%svim -u NONE -es -V %s %s",
	    \ (s:isWin() ? '' : 'TERM=vt100 LC_ALL=C '),
	    \ (s:isWin() ? wincmd : ''),
	    \ bufname)
	let msg = system(cmd)
	let msg = substitute(msg, '.*\(E325.*process ID:.\{-}\)\%x0d.*', '\1', '')
	let msg = substitute(msg, "\e\\[\\d\\+C", "", "g")
	if do_modification_check
	    let not_modified = (match(msg, "modified: no") > -1)
	endif
    endif
    if has("unix") && !empty(msg) && system("uname") =~? "linux"
	" try to get process name from pid
	" This is Linux specific.
	" TODO Is there a portable way to retrive this info for at least unix?
	let pid_pat = 'process ID:\s*\zs\d\+'
	let pid = matchstr(msg, pid_pat)+0
	if !empty(pid) && isdirectory('/proc')
	    let pname = 'not existing'
	    let proc = '/proc/'. pid. '/status'
	    if filereadable(proc)
		let pname = matchstr(readfile(proc)[0], '^Name:\s*\zs.*')
	    endif
	    let msg = substitute(msg, pid_pat, '& ['.pname."]\n", '')
	    if not_modified && pname !~? 'vim'
		let not_modified = 0
	    endif
	endif
    endif
    if executable('vim') && executable('diff') "&& s:isWin()
	" Check, whether the files differ issue #7
	" doesn't work on Windows? (cmd is ok, should be executable)
	if s:isWin()
	    let tfile = substitute(tfile, '/', '\\', 'g')
	endif
	let cmd = printf("vim -u NONE -N %s -r %s -c \":w %s|:q!\" %s diff %s %s",
		    \ (s:isWin() ? '' : '-es'),
		    \ (s:isWin() ? fnamemodify(v:swapname, ':p:8') : shellescape(v:swapname)),
		    \ tfile, (s:isWin() ? '&' : '&&'),
		    \ bufname, tfile)
	call system(cmd)
	" if return code of diff is zero, files are identical
	let delete = !v:shell_error
	if !do_modification_check
	    echo msg
	endif
    endif
    call delete(tfile)
    if delete && !do_modification_check
	echomsg "Swap and on-disk file seem to be identical"
    endif
    let cmd = printf("D&iff\n&Open Read-Only\n&Edit anyway\n&Recover\n&Quit\n&Abort%s",
		\ ( (delete || !empty(msg)) ? "\n&Delete" : ""))
    if !empty(msg)
	let info = 'Please choose: '
    else
	let info = "Swap File '". v:swapname. "' found: "
    endif
"    if has("gui_running") && &go !~ 'c'
"	call inputsave()
"	let p = confirm(info, cmd, (modified ? 3 : delete ? 7 : 1), 'I')
"    else
"	echo info
"	call s:Output(cmd)
    if not_modified
	let p = 3
    else
	call inputsave()
	let p = confirm(info, cmd, (delete ? 7 : 1), 'I')
    "    endif
	call inputrestore()
    endif
    let b:swapname=v:swapname
    if p == 1 || p == 3
	" Diff or Edit Anyway
	call s:SwapChoice('e')
	" postpone recovering until later, for now, we are opening anyways...
	" (this is done by s:CheckRecover()
	" in an BufReadPost autocommand
	if (p == 1)
	    call recover#AutoCmdBRP(1)
	endif
	" disable fencview (issue #23)
	" This is a hack, fencview doesn't allow to selectively disable it :(
        let s:fencview_autodetect = get(g:, 'fencview_autodetect', 0)
        if s:fencview_autodetect
	    setl buftype=help
        endif
    elseif p == 2
	" Open Read-Only
	" Don't show the Recovery dialog
	let v:swapchoice='o'
	call <sid>EchoMsg("Found SwapFile, opening file readonly!")
	sleep 2
    elseif p == 4
	" Recover
	let v:swapchoice='r'
    elseif p == 5
	" Quit
	let v:swapchoice='q'
    elseif p == 6
	" Abort
	let v:swapchoice='a'
    elseif p == 7
	" Delete Swap file, if not different
	call s:SwapChoice('d')
	call <sid>EchoMsg("Found SwapFile, deleting...")
	" might trigger SwapExists again!
	call s:SetSwapfile()
    else
	" Show default menu from vim
	return
    endif
endfun

fu! s:Output(msg) "{{{1
    " Display as one string, without linebreaks
    let msg = substitute(a:msg, '\n', '/', 'g')
    for item in split(msg, '&')
	echohl WarningMsg
	echon item[0]
	echohl Normal
	echon item[1:]
    endfor
endfun

fu! s:SwapChoice(char) "{{{1
    let v:swapchoice = a:char
    let b:swapchoice = a:char
endfu

fu! recover#DiffRecoveredFile() "{{{1
    " recovered version
    diffthis
    let b:mod='recovered version'
    let l:filetype = &ft
    if has("balloon_eval")
	set ballooneval
	setl bexpr=recover#BalloonExprRecover()
    endif
    " saved version
    let curspr = &spr
    set nospr
    noa vert new
    let &l:spr = curspr
    if !empty(glob(fnameescape(expand('#'))))
	0r #
	$d _
    endif
    if l:filetype != ""
	exe "setl filetype=".l:filetype
    endif
    exe "f! " . escape(expand("<afile>")," ") .
	    \ escape(' (on-disk version)', ' ')
    diffthis
    setl noswapfile buftype=nowrite bufhidden=delete nobuflisted
    let b:mod='unmodified version on-disk'
    let swapbufnr=bufnr('')
    if has("balloon_eval")
	set ballooneval
	setl bexpr=recover#BalloonExprRecover()
    endif
    noa wincmd l
    let b:swapbufnr = swapbufnr
    command! -buffer RecoverPluginFinish :FinishRecovery
    command! -buffer FinishRecovery :call recover#RecoverFinish()
    setl modified
endfu

fu! recover#Help() "{{{1
    echohl Title
    echo "Diff key mappings\n".
    \ "-----------------\n"
    echo "Normal mode commands:\n"
    echohl Normal
    echo "]c - next diff\n".
    \ "[c - prev diff\n".
    \ "do - diff obtain - get change from other window\n".
    \ "dp - diff put    - put change into other window\n"
    echohl Title
    echo "Ex-commands:\n"
    echohl Normal
    echo ":[range]diffget - get changes from other window\n".
    \ ":[range]diffput - put changes into other window\n".
    \ ":RecoverPluginDisable - DisablePlugin\n".
    \ ":RecoverPluginEnable  - EnablePlugin\n".
    \ ":RecoverPluginHelp    - this help"
    if exists(":RecoverPluginFinish")
	echo ":RecoverPluginFinish  - finish recovery"
    endif
endfun



fu! s:EchoMsg(msg) "{{{1
    echohl WarningMsg
    uns echomsg a:msg
    echohl Normal
endfu

fu! s:ModifySTL(enable) "{{{1
    if a:enable
	" Inject some info into the statusline
	let s:ostl = &stl
	let s:nstl = substitute(&stl, '%f',
		\ "\\0 %{exists('b:mod')?('['.b:mod.']') : ''}", 'g')
	let &l:stl = s:nstl
    else
	" Restore old statusline setting
	if exists("s:ostl") && s:nstl == &stl
	    let &stl=s:ostl
	endif
    endif
endfu

fu! s:SetSwapfile() "{{{1
    if &l:swf
	" Reset swapfile to use .swp extension
	sil setl noswapfile swapfile
    endif
endfu

fu! s:isWin() "{{{1
    return has("win32") || has("win16") || has("win64")
endfu
fu! recover#BalloonExprRecover() "{{{1
    " Set up a balloon expr.
    if exists("b:swapbufnr") && v:beval_bufnr!=?b:swapbufnr
	return "This buffer shows the recovered and modified version of your file"
    else
	return "This buffer shows the unmodified version of your file as it is stored on disk"
    endif
endfun

fu! recover#RecoverFinish() abort "{{{1
    let swapname = b:swapname
    let curbufnr = bufnr('')
    delcommand FinishRecovery
    exe bufwinnr(b:swapbufnr) " wincmd w"
    diffoff
    bd!
    call delete(swapname)
    diffoff
    call s:ModifySTL(0)
    exe bufwinnr(curbufnr) " wincmd w"
    call s:SetSwapfile()
    unlet! b:swapname b:did_recovery b:swapbufnr b:swapchoice
endfun

fu! recover#AutoCmdBRP(on) "{{{1
    if a:on && !exists("#SwapBRP")
	augroup SwapBRP
	    au!
	    au BufNewFile,BufReadPost <buffer> :call s:CheckRecover()
	augroup END
    elseif !a:on && exists('#SwapBRP')
	augroup SwapBRP
	    au!
	augroup END
	augroup! SwapBRP
    endif
endfu
" Old functions, not used anymore "{{{1
finish

fu! recover#DiffRecoveredFileOld() "{{{2
	" For some reason, this only works with feedkeys.
	" I am not sure  why.
	let  histnr = histnr('cmd')+1
	call feedkeys(":diffthis\n", 't')
	call feedkeys(":setl modified\n", 't')
	call feedkeys(":let b:mod='recovered version'\n", 't')
	call feedkeys(":let g:recover_bufnr=bufnr('%')\n", 't')
	let l:filetype = &ft
	call feedkeys(":vert new\n", 't')
	call feedkeys(":0r #\n", 't')
	call feedkeys(":$delete _\n", 't')
	if l:filetype != ""
	    call feedkeys(":setl filetype=".l:filetype."\n", 't')
	endif
	call feedkeys(":f! " . escape(expand("<afile>")," ") . "\\ (on-disk\\ version)\n", 't')
	call feedkeys(":let swapbufnr = bufnr('')\n", 't')
	call feedkeys(":diffthis\n", 't')
	call feedkeys(":setl noswapfile buftype=nowrite bufhidden=delete nobuflisted\n", 't')
	call feedkeys(":let b:mod='unmodified version on-disk'\n", 't')
	call feedkeys(":exe bufwinnr(g:recover_bufnr) ' wincmd w'"."\n", 't')
	call feedkeys(":let b:swapbufnr=swapbufnr\n", 't')
	"call feedkeys(":command! -buffer DeleteSwapFile :call delete(b:swapname)|delcommand DeleteSwapFile\n", 't')
	call feedkeys(":command! -buffer RecoverPluginFinish :FinishRecovery\n", 't')
	call feedkeys(":command! -buffer FinishRecovery :call recover#RecoverFinish()\n", 't')
	call feedkeys(":0\n", 't')
	if has("balloon_eval")
	"call feedkeys(':if has("balloon_eval")|:set ballooneval|setl bexpr=recover#BalloonExprRecover()|endif'."\n", 't')
	    call feedkeys(":set ballooneval|setl bexpr=recover#BalloonExprRecover()\n", 't')
	endif
	"call feedkeys(":redraw!\n", 't')
	call feedkeys(":for i in range(".histnr.", histnr('cmd'), 1)|:call histdel('cmd',i)|:endfor\n",'t')
	call feedkeys(":echo 'Found Swapfile '.b:swapname . ', showing diff!'\n", 'm')
	" Delete Autocommand
	call recover#AutoCmdBRP(0)
    "endif
endfu


" Modeline "{{{1
" vim:fdl=0
doc/recoverPlugin.txt	[[[1
260
*recover.vim*   Show differences for recovered files

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.18 Wed, 14 Aug 2013 22:39:13 +0200
Copyright: (c) 2009, 2010, 2011, 2012, 2013 by Christian Brabandt
           The VIM LICENSE applies to recoverPlugin.vim and recoverPlugin.txt
           (see |copyright|) except use recoverPlugin instead of "Vim".
           NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.


==============================================================================
1. Contents                                                    *RecoverPlugin*

        1.  Contents.....................................: |recoverPlugin|
        2.  recover Manual...............................: |recover-manual|
        3.  recover Feedback.............................: |recover-feedback|
        4.  recover History..............................: |recover-history|

==============================================================================
                                                              *RecoverPlugin-manual*
2. RecoverPlugin Manual                                       *recover-manual*

Functionality

When using |recovery|, it is hard to tell, what has been changed between the
recovered file and the actual on disk version. The aim of this plugin is, to
have an easy way to see differences, between the recovered files and the files
stored on disk.

Therefore this plugin sets up an auto command, that will create a diff buffer
between the recovered file and the on-disk version of the same file. You can
easily see, what has been changed and save your recovered work back to the
file on disk.

By default this plugin is enabled. To disable it, use >
    :RecoverPluginDisable
<
To enable this plugin again, use >
    :RecoverPluginEnable
<
When you open a file and vim detects, that an |swap-file| already exists for a
buffer, the plugin presents the default Swap-Exists dialog from Vim adding one
additional option for Diffing (but leaves out the lengthy explanation about
handling Swapfiles that Vim by default shows): >

    Found a swap file by the name "test/normal/.testfile.swp"
            owned by: chrisbra   dated: Wed Nov 28 16:26:42 2012
            file name: ~chrisbra/code/git/vim/Recover/test/normal/testfile
            modified: YES
            user name: chrisbra   host name: R500
            process ID: 4878 [not existing]
    While opening file "test/normal/testfile"
                dated: Tue Nov  6 20:11:55 2012
    Please choose:
    D[i]ff, (O)pen Read-Only, (E)dit anyway, (R)ecover, (Q)uit, (A)bort, (D)elete:


(Note, that additionally, it shows in the process ID row the name of the
process that has the process id or [not existing] if that process doesn't
exist.) Simply use the key, that is highlighted to chose the option. If you
press Ctrl-C, the default dialog of Vim will be shown.

If you have said 'Diff', the plugin opens a new vertical splitt buffer. On the
left side, you'll find the file as it is stored on disk and the right side
will contain your recovered version of the file (using the found swap file).

You can now use the |merge| commands to copy the contents to the buffer that
holds your recovered version. If you are finished, you can close the diff
version and close the window, by issuing |:diffoff!| and |:close| in the
window, that contains the on-disk version of the file. Be sure to save the
recovered version of you file and afterwards you can safely remove the swap
file.
                                        *RecoverPluginFinish* *FinishRecovery*
In the recovered window, the command >
    :FinishRecovery
<
deletes the swapfile closes the diff window and finishes everything up.

Alternatively you can also use the command >
    :RecoveryPluginFinish
<
                                                        *RecoverPluginHelp*
The command >
    :RecoverPluginHelp
<
show a small message, on what keys can be used to move to the next different
region and how to merge the changes from one windo into the other.

                                                       *RecovePlugin-config*
If you want Vim to automatically edit any file that is open in another Vim
instance but is unmodified there, you need to set the configuration variable:
g:RecoverPlugin_Edit_Unmodified to 1 like this in your |.vimrc| >

    :let g:RecoverPlugin_Edit_Unmodified = 1
<
Note: This only works on Linux.

                                                        *RecoverPlugin-misc*
If your Vim was built with |+balloon_eval|, recover.vim will also set up an
balloon expression, that shows you, which buffer contains the recovered
version of your file and which buffer contains the unmodified on-disk version
of your file, if you move the mouse of the buffer. (See |balloon-eval|).

If you have setup your 'statusline', recover.vim will also inject some info
(which buffer contains the on-disk version and which buffer contains the
modified, recovered version). Additionally the buffer that is read-only, will
have a filename (|:f|) of something like 'original file (on disk-version)'. If
you want to save that version, use |:saveas|.

==============================================================================
3. Plugin Feedback                                        *recover-feedback*

Feedback is always welcome. If you like the plugin, please rate it at the
vim-page:
http://www.vim.org/scripts/script.php?script_id=3068

You can also follow the development of the plugin at github:
http://github.com/chrisbra/Recover.vim

Please don't hesitate to report any bugs to the maintainer, mentioned in the
third line of this document.

==============================================================================
4. recover History                                          *recover-history*

0.18: Aug 14, 2013 "{{{1

- fix issue 19 (https://github.com/chrisbra/Recover.vim/issues/19, by
  replacing feedkeys("...\n") by feedkeys("...\<cr>", reported by vlmarek,
  thanks!)
- fix issue 20 (https://github.com/chrisbra/Recover.vim/issues/20,
  (let vim automatically edit a file, that is unmodified in another vim
  instance, suggested by rking, thanks!)
- merge issue 21 (https://github.com/chrisbra/Recover.vim/pull/21, create more
  usefule README.md file, contribted by Shubham Rao, thanks!)
- merge issue 22 (https://github.com/chrisbra/Recover.vim/pull/22, delete BufReadPost autocommand
  contributed by Marcin Szamotulski, thanks!)

0.17: Feb 16, 2013 "{{{1

- fix issue 17 (https://github.com/chrisbra/Recover.vim/issues/17 patch by
  lyokha, thanks!)
- Use default key combinations in the dialog of the normal Vim dialog (adding
  only the Diff option)
- Make sure, the process ID is shown

0.16: Nov 21, 2012 "{{{1

- Recovery did not work, when original file did not exists (issue 11
  https://github.com/chrisbra/Recover.vim/issues/11
  reported by Rking, thanks!)
- By default, delete swapfile, if no differences found (issue 15
  https://github.com/chrisbra/Recover.vim/issues/15
  reported by Rking, thanks!)
- reset 'swapfile' option, so that Vim by default creates .swp files
  (idea and patch by Marcin Szamotulski, thanks!)
- capture and display |E325| message (and also try to figure out the name of
  the pid (issue 12 https://github.com/chrisbra/Recover.vim/issues/12)

0.15: Aug 20, 2012 "{{{1

- fix issue 5 (https://github.com/chrisbra/Recover.vim/issues/5 patch by
  lyokha, thanks!)
- CheckSwapFileExists() hangs, when a swap file was not found, make sure,
  s:Swapname() returns a valid file name
- fix issue 6 (https://github.com/chrisbra/Recover.vim/issues/6 patch by
  lyokha, thanks!)
- Avoid recursive :redir call (https://github.com/chrisbra/Recover.vim/pull/8
  patch by Ingo Karkat, thanks!)
- Do not set 'bexpr' for unrelated buffers (
  https://github.com/chrisbra/Recover.vim/pull/9 patch by Ingo Karkat,
  thanks!)
- Avoid aborting the diff (https://github.com/chrisbra/Recover.vim/pull/10
  patch by Ingo Karkat, thanks!)
- Allow to directly delete the swapfile (
  https://github.com/chrisbra/Recover.vim/issues/7 suggested by jgandt,
  thanks!)

0.14: Mar 31, 2012 "{{{1

- still some problems with issue #4

0.13: Mar 29, 2012 "{{{1

- fix issue 3 (https://github.com/chrisbra/Recover.vim/issues/3 reported by
  lyokha, thanks!)
- Ask the user to delete the swapfile (issue
  https://github.com/chrisbra/Recover.vim/issues/4 reported by lyokha,
  thanks!)

0.12: Mar 25, 2012 "{{{1

- minor documentation update
- delete swap files, if no difference found (issue
  https://github.com/chrisbra/Recover.vim/issues/1 reported by y, thanks!)
- fix some small issues, that prevented the development versions from working
  (https://github.com/chrisbra/Recover.vim/issues/2 reported by Rahul Kumar,
  thanks!)

0.11: Oct 19, 2010 "{{{1

- use confirm() instead of inputdialog() (suggested by D.Fishburn, thanks!)

0.9: Jun 02, 2010 "{{{1

- use feedkeys(...,'t') instead of feedkeys() (this works more reliable,
  although it pollutes the history), so delete those spurious history entries
- |RecoverPluginHelp| shows a small help message, about diff commands
  (suggested by David Fishburn, thanks!)
- |RecoverPluginFinish| is a shortcut for |FinishRecovery|

0.8: Jun 01, 2010 "{{{1

- make :FinishRecovery more robust

0.7: Jun 01, 2010 "{{{1

- |FinishRecovery| closes the diff-window and cleans everything up (suggestion
  by David Fishburn)
- DeleteSwapFile is not needed anymore

0.6: May 31, 2010 "{{{1

- |recover-feedback|
- Ask to really open a diff buffer for a file (suggestion: David Fishburn,
  thanks!)
- DeleteSwapFile to delete the swap file, that was used to create the diff
  buffer
- change feedkeys(...,'t') to feedkeys('..') so that not every command appears
  in the history.

0.5: May 04, 2010 "{{{1

- 0r command in recover plugin adds extra \n
  Patch by Sergey Khorev (Thanks!)
- generate help file with 'et' set, so the README at github looks prettier

0.4: Apr 26, 2010 "{{{1

- handle Windows and Unix path differently
- Code cleanup
- Enabled |:GLVS|

0.3: Apr 20, 2010 "{{{1

- first public verion
- put plugin on a public repository
  (http://github.com/chrisbra/Recover.vim)

0.2: Apr 18, 2010 "{{{1

- Internal version, some cleanup, bugfixes for windows

0.1: Apr 17, 2010 "{{{1

- Internal version, First working version, using simple commands

==============================================================================
Modeline: "{{{1
vim:tw=78:ts=8:ft=help:et:fdm=marker:fdl=0:norl
