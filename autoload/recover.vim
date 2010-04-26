" Vim plugin for diffing when swap file was found
" ---------------------------------------------------------------
" Author: Christian Brabandt <cb@256bit.org>
" Version: 0.3
" Last Change: Tue, 20 Apr 2010 23:59:22 +0200


" Script:  Not Yet
" License: VIM License
" GetLatestVimScripts: Not Yet
"
fu! recover#Recover(on) "{{{1
    if a:on
	call s:ModifySTL()
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
	"let g:diff_file=0
    endif
    "echo "RecoverPlugin" (a:on ? "Enabled" : "Disabled")
endfu

fu! recover#AutoCmdBRP(on) "{{{1
    if a:on
	    augroup SwapBRP
	    au!
	    "exe ":au BufReadPost " substitute(escape(fnamemodify(expand('<afile>'), ':p'), ' \\'), '\\', '/', 'g') " :call recover#DiffRecoveredFile()"
	    " Escape spaces and backslashes
	    " substitute backslashes with forward slashes so that it works
	    " with windows (ok this might cause trouble with files, that have
	    " a backslash in their name, as it could happen on Unix)
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
    "if exists("g:diff_file") && g:diff_file==1
	" For some reason, this only works with feedkeys.
	" I am not sure  why.
	call feedkeys(":diffthis\n", "t")
	call feedkeys(":setl modified\n", "t")
	call feedkeys(":let b:mod='recovered version'\n", "t")
	call feedkeys(":vert new\n", "t")
	call feedkeys(":0r #\n", "t")
	call feedkeys(":f! " . escape(expand("<afile>")," ") . "\\ (on-disk\\ version)\n", "t")
	call feedkeys(":diffthis\n", "t")
	call feedkeys(":set bt=nowrite\n", "t")
	call feedkeys(":let b:mod='unmodified version on-disk'\n", "t")
	call feedkeys(':if has("balloon_eval")|:set ballooneval|set bexpr=recover#BalloonExprRecover()|endif'."\n", 't')
	"call feedkeys(":redraw!\n", "t")
	call feedkeys(":echo 'Found Swapfile, showing diff!'\n", "t")
	"unlet g:diff_file
	" Delete Autocommand
	"call recover#Recover(0)
	call recover#AutoCmdBRP(0)
    "endif
endfu

fu! s:EchoMsg(msg) "{{{1
    echohl WarningMsg
    echomsg a:msg
    echohl Normal
endfu

fu! s:ModifySTL() "{{{1
    :let s:ostl=&stl
    :let &stl=substitute(&stl, '%f', "\\0 %{exists('b:mod')?('['.b:mod.']') : ''}", 'g')
endfu

fu! s:ResetSTL() "{{{1
    if exists("s:ostl")
	let &stl=s:ostl
    endif
endfu

fu! recover#BalloonExprRecover() "{{{1
    if exists("b:mod") 
	return "This buffer shows the ".b:mod. " of your file"
    endif
endfun

