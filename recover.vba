" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/recover.vim	[[[1
34
" Vim plugin for diffing when swap file was found
" Last Change: Tue, 20 Apr 2010 23:59:22 +0200

" Version: 0.3
" Author: Christian Brabandt <cb@256bit.org>
" Script:  http://www.vim.org/scripts/script.php?script_id=2709 
" License: VIM License
" GetLatestVimScripts: Not yet enabled
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
88
" Vim plugin for diffing when swap file was found
" ---------------------------------------------------------------
" Author: Christian Brabandt <cb@256bit.org>
" Version: 0.3
" Last Change: Tue, 20 Apr 2010 23:59:22 +0200


" Script:  Not Yet
" License: VIM License
" GetLatestVimScripts: Not Yet
"
fu! recover#Recover(on)
    if a:on
	call recover#ModifySTL()
	if !exists("s:old_vsc")
	    let s:old_vsc = v:swapchoice
	endif
	augroup Swap
	    au!
	    au SwapExists * :let v:swapchoice='r'|call recover#AutoCmdBRP(1)
	    "au SwapExists * :let v:swapchoice='r'|:let g:diff_file=1|exe "au BufReadPost " substitute(fnamemodify(expand('<afile>'), ':p'), '\\', '/', 'g') " :call recover#DiffRecoveredFile()"
	    "au SwapExists * :let v:swapchoice='r'|exe "augroup Swap|au!|au BufReadPost " fnamemodify(expand('<afile>'), ':p') " :call recover#DiffRecoveredFile()|augroup end"
	    "au SwapExists * :echomsg "SwapExists autocommand"
	augroup END
    else
	augroup Swap
	    au!
	augroup end
	if exists("s:old_vsc")
	    let v:swapchoice=s:old_vsc
	endif
	"call recover#ResetSTL()
	let g:diff_file=0
    endif
    echo "RecoverPlugin" (a:on ? "Enabled" : "Disabled")
endfu

fu! recover#AutoCmdBRP(on)
    if a:on
	    augroup SwapBRP
	    au!
	    exe ":au BufReadPost " substitute(escape(fnamemodify(expand('<afile>'), ':p'), ' '), '\\', '/', 'g') " :call recover#DiffRecoveredFile()"
	    augroup END
    else
	    augroup SwapBRP
	    au!
	    augroup END
    endif
endfu

fu! recover#DiffRecoveredFile()
    "if exists("g:diff_file") && g:diff_file==1
	" For some reason, this only works with feedkeys.
	" I am not sure  why.
	call feedkeys(":diffthis\n", "t")
	call feedkeys(":setl modified\n", "t")
	call feedkeys(":let b:mod='recovered version'\n", "t")
	call feedkeys(":noa vert new\n", "t")
	call feedkeys(":0r #\n", "t")
	call feedkeys(":f! " . escape(expand("<afile>")," ") . "\\ (on-disk\\ version)\n", "t")
	call feedkeys(":diffthis\n", "t")
	call feedkeys(":set bt=nowrite\n", "t")
	call feedkeys(":let b:mod='unmodified version on-disk'\n", "t")
	"call feedkeys(":redraw!\n", "t")
	call feedkeys(":echo 'Found Swapfile, showing diff!'\n", "t")
	unlet g:diff_file
	" Delete Autocommand
	"call recover#Recover(0)
	call recover#AutoCmdBRP(0)
    "endif
endfu

fu! recover#EchoMsg(msg)
    echohl WarningMsg
    echomsg a:msg
    echohl Normal
endfu

fu! recover#ModifySTL()
    :let s:ostl=&stl
    :let &stl=substitute(&stl, '%f', "\\0 %{exists('b:mod')?('['.b:mod.']') : ''}", 'g')
endfu

fu! recover#ResetSTL()
    if exists("s:ostl")
	let &stl=s:ostl
    endif
endfu
doc/recoverPlugin.txt	[[[1
53
*recover.vim*	Show differences for recovered files

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.3 Wed, 21 Apr 2010 00:00:13 +0200

Copyright: (c) 2009, 2010 by Christian Brabandt		
           The VIM LICENSE applies to SudoEdit.vim and SudoEdit.txt
           (see |copyright|) except use SudoEdit instead of "Vim".
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


==============================================================================
3. recover History					    *recover-history*
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
