" Vim plugin for diffing when swap file was found
" ---------------------------------------------------------------
" Author: Christian Brabandt <cb@256bit.org>
" Version: 0.19
" Last Change: Thu, 15 Jan 2015 21:26:55 +0100
" Script:  http://www.vim.org/scripts/script.php?script_id=3068
" License: VIM License
" GetLatestVimScripts: 3068 19 :AutoInstall: recover.vim
"
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

fu! recover#CheckSwapFileExists() "{{{1
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
	" Don't delete the auto command yet.
	"call recover#AutoCmdBRP(0)
    endif
    if get(s:, 'fencview_autodetect', 0)
	setl buftype=
    endif
endfun

fu! recover#ConfirmSwapDiff() "{{{1
    if exists("b:swapchoice")
	let v:swapchoice = b:swapchoice
	return
    endif
    call s:ModifySTL(1)
    let delete = 0
    let do_modification_check = exists("g:RecoverPlugin_Edit_Unmodified") ? g:RecoverPlugin_Edit_Unmodified : 0
    let not_modified = 0
    let msg = ""
    let bufname = s:isWin() ? fnamemodify(expand('%'), ':p:8') : shellescape(expand('%'))
    let tfile = tempname()
    if executable('vim') && !s:isWin() && !s:isMacTerm()
	" Doesn't work on windows (system() won't be able to fetch the output)
	" and Mac Terminal (issue #24)  
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
	    au BufReadPost <buffer> :setl buftype=
        endif
    elseif p == 2
	" Open Read-Only
	" Don't show the Recovery dialog
	let v:swapchoice='o'
	call <sid>EchoMsg("Found SwapFile, opening file readonly!")
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
    command! -buffer RecoverPluginGet :1,$+1diffget|:FinishRecovery
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
    if &l:swf && !empty(bufname(''))
	" Reset swapfile to use .swp extension
	sil setl noswapfile swapfile
    endif
endfu

fu! s:isWin() "{{{1
    return has("win32") || has("win16") || has("win64")
endfu
fu! s:isMacTerm() "{{{1
    return (has("mac") || has("macunix")) && !has("gui_mac")
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
    call delete(fnameescape(swapname))
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
