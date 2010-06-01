" Vim plugin for diffing when swap file was found
" ---------------------------------------------------------------
" Author: Christian Brabandt <cb@256bit.org>
" Version: 0.8
" Last Change: Tue, 01 Jun 2010 20:54:03 +0200
" Script:  http://www.vim.org/scripts/script.php?script_id=3068
" License: VIM License
" GetLatestVimScripts: 3068 6 :AutoInstall: recover.vim
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
	call feedkeys(":let swapbufnr = bufnr('')\n")
	call feedkeys(":diffthis\n")
	call feedkeys(":setl noswapfile buftype=nowrite bufhidden=delete nobuflisted\n")
	call feedkeys(":let b:mod='unmodified version on-disk'\n")
	call feedkeys(":exe bufwinnr(g:recover_bufnr) ' wincmd w'"."\n")
	call feedkeys(":let b:swapbufnr=swapbufnr\n")
	"call feedkeys(":command! -buffer DeleteSwapFile :call delete(b:swapname)|delcommand DeleteSwapFile\n")
	call feedkeys(":command! -buffer FinishRecovery :call recover#RecoverFinish()\n")
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

fu! recover#RecoverFinish() abort "{{{1
    diffoff
    exe bufwinnr(b:swapbufnr) " wincmd w"
    diffoff
    bd!
    call delete(b:swapname)
    delcommand FinishRecovery
endfun

" vim:fdl=0
