" FOOBAR TEST
" Vim plugin for diffing when swap file was found
" ---------------------------------------------------------------
" Author: Christian Brabandt <cb@256bit.org>
" Version: 0.13
" Last Change: Sun, 25 Mar 2012 20:52:25 +0200
" Script:  http://www.vim.org/scripts/script.php?script_id=3068
" License: VIM License
" GetLatestVimScripts: 3068 11 :AutoInstall: recover.vim
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
	sil! "setl noswapfile swapfile"
    endif
endfu


fu! s:CheckRecover() "{{{1
    let winnr = winnr()
    if exists("b:swapname") && !exists("b:did_recovery")
	exe "recover" fnameescape(expand('%:p'))
	let  t = tempname()
	exe "sil w!" t
	call system('diff '. shellescape(expand('%:p'),1).
		    \ ' '. shellescape(t,1))
	if !v:shell_error
	    call <sid>EchoMsg("No differences, deleting old swap file")
	    call delete(b:swapname)
	else
	    call recover#DiffRecoveredFile()
	    let b:did_process_recovery=1
	    " Not sure, why this needs feedkeys
	    " Sometimes, I hate when this happens
	    call feedkeys(":wincmd p\n\n", 't')
	endif
	let b:did_recovery=1
    endif
endfun


fu! recover#SwapFoundComplete(A,L,P) "{{{1
    return "Yes\nNo"
endfu

fu! recover#ConfirmSwapDiff() "{{{1
    call inputsave()
    let p = confirm("Swap File found: Diff buffer? ", "&Yes\n&No")
    call inputrestore()
    let b:swapname=v:swapname
    if p == 1
	let v:swapchoice='r'
	" postpone recovering until later (this is done by s:CheckRecover()
	" in an BufReadPost autocommand
	call recover#AutoCmdBRP(1)
    else
	" Don't show the Recovery dialog
	let v:swapchoice='o'
	call <sid>EchoMsg("Found SwapFile, opening file readonly!")
	sleep 2
    endif
endfun

fu! recover#DiffRecoveredFile() "{{{1
	diffthis
	let b:mod='recovered version'
	let l:filetype = &ft
	noa vert new
	0r #
	$d _
	if l:filetype != ""
	    exe "setl filetype=".l:filetype
	endif
	exe "f! " . escape(expand("<afile>")," ") .
		\ escape(' (on-disk version)', ' ')
	let swapbufnr = bufnr('')
	diffthis
	setl noswapfile buftype=nowrite bufhidden=delete nobuflisted
	let b:mod='unmodified version on-disk'
	noa wincmd p
	let b:swapbufnr=swapbufnr
	command! -buffer RecoverPluginFinish :FinishRecovery
	command! -buffer FinishRecovery :call recover#RecoverFinish()
	0
	if has("balloon_eval")
	    set ballooneval bexpr=recover#BalloonExprRecover()
	endif
	setl modified
	echo 'Found Swapfile '.b:swapname . ', showing diff!'
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
	:let s:ostl=&stl
	:let &stl=substitute(&stl, '%f', "\\0 %{exists('b:mod')?('['.b:mod.']') : ''}", 'g')
    else
	" Restore old statusline setting
	if exists("s:ostl")
	    let &stl=s:ostl
	endif
    endif
endfu

fu! recover#BalloonExprRecover() "{{{1
    " Set up a balloon expr.
    if exists("b:mod") 
	if v:beval_bufnr==?b:swapbufnr
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
    call s:ModifySTL(0)
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
