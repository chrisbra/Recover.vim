" Vim plugin for diffing when swap file was found
" Last Change: Thu, 15 Jan 2015 21:26:55 +0100
" Version: 0.19
" Author: Christian Brabandt <cb@256bit.org>
" Script:  http://www.vim.org/scripts/script.php?script_id=3068 
" License: VIM License
" GetLatestVimScripts: 3068 18 :AutoInstall: recover.vim
" Documentation: see :h recoverPlugin.txt

" ---------------------------------------------------------------------
" Load Once: {{{1
if exists("g:loaded_recover") || &cp
  finish
endif
let g:loaded_recover = 1"}}}
let s:keepcpo          = &cpo
set cpo&vim

fu! s:Recover(on) "{{{1
    if a:on
	if !exists("s:old_vsc")
	    let s:old_vsc = v:swapchoice
	endif
	augroup Swap
	    au!
	    au SwapExists * nested :call recover#ConfirmSwapDiff()
	    au BufWinEnter,InsertEnter,InsertLeave,FocusGained *
			\ call recover#CheckSwapFileExists()
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


" ---------------------------------------------------------------------
" Public Interface {{{1
" Define User-Commands and Autocommand "{{{
call s:Recover(1)

com! RecoverPluginEnable  :call s:Recover(1)
com! RecoverPluginDisable :call s:Recover(0)
com! RecoverPluginHelp    :call recover#Help()

" =====================================================================
" Restoration And Modelines: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo

" Modeline {{{1
" vim: fdm=marker sw=2 sts=2 ts=8 fdl=0
