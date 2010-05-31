" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/recover.vim	[[[1
33
" Vim plugin for diffing when swap file was found
" Last Change: Mon, 31 May 2010 22:39:40 +0200
" Version: 0.6
" Author: Christian Brabandt <cb@256bit.org>
" Script:  http://www.vim.org/scripts/script.php?script_id=3068 
" License: VIM License
" GetLatestVimScripts: 3068 4 :AutoInstall: recover.vim
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
137
" Vim plugin for diffing when swap file was found
" ---------------------------------------------------------------
" Author: Christian Brabandt <cb@256bit.org>
" Version: 0.6
" Last Change: Mon, 31 May 2010 22:39:40 +0200
" Script:  http://www.vim.org/scripts/script.php?script_id=3068
" License: VIM License
" GetLatestVimScripts: 3068 4 :AutoInstall: recover.vim
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
	    "au SwapExists * let v:swapchoice='r'|let b:swapname=v:swapname|call recover#AutoCmdBRP(1)
	    au SwapExists * call recover#ConfirmSwapDiff()
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

fu! recover#SwapFoundComplete(A,L,P) "{{{1
    return "Yes\nNo"
endfu

fu! recover#ConfirmSwapDiff() "{{{1
	call inputsave()
	if has("gui_running")
	   let p = inputdialog("Swap File found: Diff buffer? ", "Yes", "No")
	else
	   let p = input("Swap File found: Diff buffer? ", "Yes", "custom,recover#SwapFoundComplete")
	endif
	call inputrestore()
	if p =~? '^y\%[es]$'
	    let v:swapchoice='r'
	    let b:swapname=v:swapname
	    call recover#AutoCmdBRP(1)
	endif
endfun

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
	call feedkeys(":diffthis\n")
	call feedkeys(":setl modified\n")
	call feedkeys(":let b:mod='recovered version'\n")
	call feedkeys(":let g:recover_bufnr=bufnr('%')\n")
	let l:filetype = &ft
	call feedkeys(":vert new\n")
	call feedkeys(":0r #\n")
	call feedkeys(":$delete _\n")
	if l:filetype != ""
		call feedkeys(":setl filetype=".l:filetype."\n")
	endif
	call feedkeys(":f! " . escape(expand("<afile>")," ") . "\\ (on-disk\\ version)\n")
	call feedkeys(":diffthis\n")
	call feedkeys(":setl noswapfile buftype=nowrite bufhidden=delete nobuflisted\n")
	call feedkeys(":let b:mod='unmodified version on-disk'\n")
	call feedkeys(":wincmd p\n")
	call feedkeys(":command! -buffer DeleteSwapFile :call delete(b:swapname)\n")
	call feedkeys(":0\n")
	call feedkeys(':if has("balloon_eval")|:set ballooneval|set bexpr=recover#BalloonExprRecover()|endif'."\n")
	"call feedkeys(":redraw!\n")
	call feedkeys(":echo 'Found Swapfile '.b:swapname . ', showing diff!'\n")
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
111
*recover.vim*   Show differences for recovered files

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.6 Mon, 31 May 2010 22:39:40 +0200

Copyright: (c) 2009, 2010 by Christian Brabandt         
           The VIM LICENSE applies to recoverPlugin.vim and recoverPlugin.txt
           (see |copyright|) except use recoverPlugin instead of "Vim".
           NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.


==============================================================================
1. Contents                                                     *recoverPlugin*

        1.  Contents.....................................: |recoverPlugin|
        2.  recover Manual...............................: |recover-manual|
        3.  recover Feedback.............................: |recover-feedback|
        4.  recover History..............................: |recover-history|

==============================================================================
2. recover Manual                                       *recover-manual*

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

To enable this plugin again, use >
    :RecoverPluginEnable

When you open a file and vim detects, that an |swap-file| already exists for a
buffer, the plugin will ask you, if you'd like to see a diff of both versions
using |vimdiff|. In the dialog answer 'Yes' to open the file and display a
diff version or 'No' to open the file normally.

If you have said 'Yes', the plugin opens a new vertical splitt buffer. On the
left side, you'll find the file as it is stored on disk and the right side
will contain your recovered version of the file (using the found swap file).

You can now use the |merge| commands to copy the contents to the buffer that
holds your recovered version. If you are finished, you can close the diff
version and close the window, by issuing |:diffoff!| and |:close| in the
window, that contains the on-disk version of the file. Be sure to save the
recovered version of you file and afterwards you can safely remove the swap
file. In the recovered window, the command >
    :DeleteSwapFile
<
to delete the swapfile, that was used to create the diff window.

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
3. ChangesPlugin Feedback                                   *recover-feedback*

Feedback is always welcome. If you like the plugin, please rate it at the
vim-page:
http://www.vim.org/scripts/script.php?script_id=3068

You can also follow the development of the plugin at github:
http://github.com/chrisbra/Recover.vim

Please don't hesitate to report any bugs to the maintainer, mentioned in the
third line of this document.

==============================================================================
4. recover History                                          *recover-history*
        0.6: May 31, 2010       : |recover-feedback|
                                : Ask to really open a diff buffer for a 
                                  file (suggestion: David Fishburn, thanks!)
                                : DeleteSwapFile to delete the swap file, that
                                  was used to create the diff buffer
                                : change feedkeys(...,'t') to feedkeys('..')
                                  so that not every command appears in the
                                  history.
        0.5: May 04, 2010       :0r command in recover plugin adds extra \n
                                  Patch by Sergey Khorev (Thanks!)
                                : generate help file with 'et' set, so the 
                                  README at github looks prettier
        0.4: Apr 26, 2010       : handle Windows and Unix path differently
                                : Code cleanup
                                : Enabled |:GLVS|
        0.3: Apr 20, 2010       : first public verion
                                : put plugin on a public repository 
                                  (http://github.com/chrisbra/Recover.vim)
        0.2: Apr 18, 2010       : Internal version, some cleanup,
                                  bugfixes for windows
        0.1: Apr 17, 2010       : Internal version, First working version, 
                                  using simple commands

==============================================================================
Modeline:
vim:tw=78:ts=8:ft=help:et
