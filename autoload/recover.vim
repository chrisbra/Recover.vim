" Vim plugin for diffing when swap file was found
" ---------------------------------------------------------------
" Author: Christian Brabandt <cb@256bit.org>
" Version: 0.14
" Last Change: Sat, 31 Mar 2012 13:29:07 +0200
" Script:  http://www.vim.org/scripts/script.php?script_id=3068
" License: VIM License
" GetLatestVimScripts: 3068 14 :AutoInstall: recover.vim
"
fu! recover#Recover(on) "{{{1
    if a:on
	call s:ModifySTL(1)
	if !exists("s:old_vsc")
	    let s:old_vsc = v:swapchoice
	endif
	augroup Swap
	    au!
	    au SwapExists * call recover#ConfirmSwapDiff()
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

fu! s:Swapname() "{{{¹
    redir => a |sil swapname|redir end
    return a[1:]
endfu

fu! s:CheckSwapFileExists() "{{{1
    if !&swapfile 
	return
    endif

    if !filereadable(s:Swapname())
	" previous SwapExists autocommand deleted our swapfile,
	" recreate it and avoid E325 Message
	sil! setl noswapfile swapfile
    endif
endfu

fu! s:CheckRecover() "{{{1
    if exists("b:swapname") && !exists("b:did_recovery")
	let t = tempname()
	" Doing manual recovery, otherwise, BufRead autocmd seems to
	" get into the way of the recovery
	exe 'recover' fnameescape(expand('%:p'))
	exe ':sil w' t
	call system('diff '. shellescape(expand('%:p'),1).
		    \ ' '. shellescape(t,1))
	if !v:shell_error
	    call inputsave()
	    let p = confirm("No differences: Delete old swap file?",
		    \ "&No\n&Yes")
	    call inputrestore()
	    if p == 2
		" Workaround for E305 error
		let v:swapchoice=''
		call delete(b:swapname)
	    endif
	else
	    echo 'Found Swapfile '.b:swapname . ', showing diff!'
	    call recover#DiffRecoveredFile()
	    " Not sure, why this needs feedkeys
	    " Sometimes cursor is wrong, I hate when this happens
	    call feedkeys(":wincmd p\n:0\n", 't')
	endif
	let b:did_recovery = 1
    endif
endfun

fu! recover#ConfirmSwapDiff() "{{{1
    call inputsave()
    let p = confirm("Swap File found: Diff buffer? ", "&Yes\n&No\n&Abort")
    call inputrestore()
    let b:swapname=v:swapname
    if p == 1
	let v:swapchoice='e'
	" postpone recovering until later, for now, we are opening anyways...
	" (this is done by s:CheckRecover()
	" in an BufReadPost autocommand
	call recover#AutoCmdBRP(1)
    elseif p == 2
	" Don't show the Recovery dialog
	let v:swapchoice='o'
	call <sid>EchoMsg("Found SwapFile, opening file readonly!")
	sleep 2
    else
	" Show default menu from vim
	return
    endif
endfun

fu! recover#DiffRecoveredFile() "{{{1
    " recovered version
    diffthis
    let b:mod='recovered version'
    let l:filetype = &ft
    " saved version
    noa vert new
    0r #
    $d _
    if l:filetype != ""
	exe "setl filetype=".l:filetype
    endif
    exe "f! " . escape(expand("<afile>")," ") .
	    \ escape(' (on-disk version)', ' ')
    diffthis
    setl noswapfile buftype=nowrite bufhidden=delete nobuflisted
    let b:mod='unmodified version on-disk'
    let swapbufnr=bufnr('')
    noa wincmd p
    let b:swapbufnr = swapbufnr
    command! -buffer RecoverPluginFinish :FinishRecovery
    command! -buffer FinishRecovery :call recover#RecoverFinish()
    if has("balloon_eval")
	set ballooneval bexpr=recover#BalloonExprRecover()
    endif
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

fu! recover#BalloonExprRecover() "{{{1
    " Set up a balloon expr.
    if exists("b:swapbufnr") && v:beval_bufnr!=?b:swapbufnr
	return "This buffer shows the recovered and modified version of your file"
    else
	return "This buffer shows the unmodified version of your file as it is stored on disk"
    endif
endfun

fu! recover#RecoverFinish() abort "{{{1
    exe bufwinnr(b:swapbufnr) " wincmd w"
    diffoff
    bd!
    call delete(b:swapname)
    delcommand FinishRecovery
    diffoff
    call s:ModifySTL(0)
    unlet! b:swapname b:did_recovery b:swapbufnr
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
		exe ":au BufReadPost "
		    \ escape(substitute(fnamemodify(expand('<afile>'),
		    \ ':p'), '\\', '/', 'g'), ' \\')"
		    \ :call s:CheckRecover()"
	    else
		exe ":au BufReadPost " escape(fnamemodify(expand('<afile>'),
		    \ ':p'), ' \\')" :call s:CheckRecover()"
	    endif
	augroup END
    else
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
	"call feedkeys(':if has("balloon_eval")|:set ballooneval|set bexpr=recover#BalloonExprRecover()|endif'."\n", 't')
	    call feedkeys(":set ballooneval|set bexpr=recover#BalloonExprRecover()\n", 't')
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
