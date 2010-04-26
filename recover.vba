" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/recover.vim	[[[1
34
" Vim plugin for diffing when swap file was found
" Last Change: Mon, 26 Apr 2010 23:23:41 +0200

" Version: 0.4
" Author: Christian Brabandt <cb@256bit.org>
" Script:  http://www.vim.org/scripts/script.php?script_id=2709 
" License: VIM License
" GetLatestVimScripts: 3068 2 :AutoInstall: recover.vim
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

" =====================================================================
" Restoration And Modelines: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo

" Modeline {{{1
" vim: fdm=marker sw=2 sts=2 ts=8 fdl=0
autoload/recover.vim	[[[1
111
" Vim plugin for diffing when swap file was found
" ---------------------------------------------------------------
" Author: Christian Brabandt <cb@256bit.org>
" Version: 0.4
" Last Change: Mon, 26 Apr 2010 23:23:41 +0200


" Script:  Not Yet
" License: VIM License
" GetLatestVimScripts: 3068 2 :AutoInstall: recover.vim
"
fu! recover#Recover(on) "{{{1
    if a:on
	call s:ModifySTL()
	if !exists("s:old_vsc")
	    let s:old_vsc = v:swapchoice
	endif
	augroup Swap
	    au!
	    " The check for l:ro won't be needed, since the SwapExists
	    " auto-command won't fire anyway, if the buffer is not modifiable.
	    "au SwapExists * :if !(&l:ro)|let v:swapchoice='r'|let b:swapname=v:swapname|call recover#AutoCmdBRP(1)|endif
	    au SwapExists * let v:swapchoice='r'|let b:swapname=v:swapname|call recover#AutoCmdBRP(1)
	augroup END
    else
	augroup Swap
	    au!
	augroup end
	if exists("s:old_vsc")
	    let v:swapchoice=s:old_vsc
	endif
	"call recover#ResetSTL()
	"let g:diff_file=0
    endif
    "echo "RecoverPlugin" (a:on ? "Enabled" : "Disabled")
endfu

fu! recover#AutoCmdBRP(on) "{{{1
    if a:on
	    augroup SwapBRP
	    au!
	    " Escape spaces and backslashes
	    " On windows, we can simply replace the backslashes by forward
	    " slashes, since backslashes aren't allowed there anyway. On Unix,
	    " backslashes might exists in the path, so we handle this
	    " situation there differently.
	    if has("win16") || has("win32") || has("win64") || has("win32unix")
		exe ":au BufReadPost " escape(substitute(fnamemodify(expand('<afile>'), ':p'), '\\', '/', 'g'), ' \\')" :call recover#DiffRecoveredFile()"
	    else
		exe ":au BufReadPost " escape(fnamemodify(expand('<afile>'), ':p'), ' \\')" :call recover#DiffRecoveredFile()"
	    endif
	    augroup END
    else
	    augroup SwapBRP
	    au!
	    augroup END
    endif
endfu

fu! recover#DiffRecoveredFile() "{{{1
	" For some reason, this only works with feedkeys.
	" I am not sure  why.
	call feedkeys(":diffthis\n", "t")
	call feedkeys(":setl modified\n", "t")
	call feedkeys(":let b:mod='recovered version'\n", "t")
	call feedkeys(":let g:recover_bufnr=bufnr('%')\n", "t")
	call feedkeys(":vert new\n", "t")
	call feedkeys(":0r #\n", "t")
	call feedkeys(":f! " . escape(expand("<afile>")," ") . "\\ (on-disk\\ version)\n", "t")
	call feedkeys(":diffthis\n", "t")
	call feedkeys(":set bt=nowrite\n", "t")
	call feedkeys(":let b:mod='unmodified version on-disk'\n", "t")
	call feedkeys(":wincmd p\n","t")
	call feedkeys(':if has("balloon_eval")|:set ballooneval|set bexpr=recover#BalloonExprRecover()|endif'."\n", 't')
	"call feedkeys(":redraw!\n", "t")
	call feedkeys(":echo 'Found Swapfile '.b:swapname . ', showing diff!'\n", "t")
	" Delete Autocommand
	call recover#AutoCmdBRP(0)
    "endif
endfu

fu! s:EchoMsg(msg) "{{{1
    echohl WarningMsg
    echomsg a:msg
    echohl Normal
endfu

fu! s:ModifySTL() "{{{1
    " Inject some info into the statusline
    :let s:ostl=&stl
    :let &stl=substitute(&stl, '%f', "\\0 %{exists('b:mod')?('['.b:mod.']') : ''}", 'g')
endfu

fu! s:ResetSTL() "{{{1
    " Restore old statusline setting
    if exists("s:ostl")
	let &stl=s:ostl
    endif
endfu

fu! recover#BalloonExprRecover() "{{{1
    " Set up a balloon expr.
    if exists("b:mod") 
	if v:beval_bufnr==?g:recover_bufnr
	    return "This buffer shows the recovered and modified version of your file"
	else
	    return "This buffer shows the unmodified version of your file as it is stored on disk"
	endif
    endif
endfun

doc/recoverPlugin.txt	[[[1
66
*recover.vim*	Show differences for recovered files

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.4 Mon, 26 Apr 2010 23:23:41 +0200

Copyright: (c) 2009, 2010 by Christian Brabandt		
           The VIM LICENSE applies to recoverPlugin.vim and recoverPlugin.txt
           (see |copyright|) except use recoverPlugin instead of "Vim".
	   NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.


==============================================================================
1. Contents							*recoverPlugin*

	1.  Contents.....................................: |recoverPlugin|
	2.  recover Manual...............................: |recover-manual|
	3.  recover History..............................: |recover-history|

==============================================================================
2. recover Manual					*recover-manual*

Functionality

When using |recovery|, it is hard to tell, what has been changed between the
recovered file and the actual on disk version. The aim of this plugin is, to
have an easy way to see differences, between the recovered files and the files
restored on disk.

Therefore this plugin sets up an auto command, that will create a diff buffer
between the recovered file and the on-disk version of the same file. You can
easily see, what has been changed and save your recovered work back to the
file on disk.

By default this plugin is enabled. To disable it, use >
    :RecoverPluginDisable

To enable this plugin again, use >
    :RecoverPluginEnable

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
3. recover History					    *recover-history*
	0.4: Apr 26, 2010       : handle Windows and Unix path differently
	                        : Code cleanup
				: Enabled |:GLVS|
	0.3: Apr 20, 2010       : first public verion
				: put plugin on a public repository 
				  (http://github.com/chrisbra/Recover.vim)
	0.2: Apr 18, 2010       : Internal version, some cleanup,
	                          bugfixes for windows
	0.1: Apr 17, 2010	: Internal version, First working version, 
				  using simple commands

==============================================================================
Modeline:
vim:tw=78:ts=8:ft=help
