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
