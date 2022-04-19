" Vim plugin for diffing when swap file was found
" ---------------------------------------------------------------
" Author: Christian Brabandt <cb@256bit.org>
" Version: 0.19
" Last Change: Thu, 15 Jan 2015 21:26:55 +0100
" Script:  http://www.vim.org/scripts/script.php?script_id=3068
" License: VIM License
" GetLatestVimScripts: 3068 19 :AutoInstall: recover.vim

let s:progpath=(v:version > 704 || (v:version == 704 && has("patch234")) ? v:progpath : 'vim')
let s:swapinfo=exists("*swapinfo")
" Assume linux, when the /proc directory is there.
" Note: system('uname') might be slow, so fall back to using isdirectory('/proc')
"let s:is_linux = has("unix") && system('uname') =~? 'linux'
let s:is_linux = has("unix") && isdirectory('/proc')

fu! s:Swapname() "{{{1
  " Use sil! so a failing redir (e.g. recursive redir call)
  " won't hurt. (https://github.com/chrisbra/Recover.vim/pull/8)
  if exists('*execute') && exists('*trim')
    let a=trim(execute('swapname'))
  else
    sil! redir => a |sil swapname|redir end
  endif
  if a[1:] == 'No swap file'
    return ''
  else
    return a[0] ==# '\n' ? a[1:] : a
  endif
endfu
fu! s:PIDName(pid) "{{{1
  " Return name of process for given pid
  " only works on linux with /proc filesystem
  if !empty(a:pid) && s:is_linux
    let pname = 'not existing'
    let proc = '/proc/'. a:pid. '/status'
    if filereadable(proc)
      let pname = matchstr(readfile(proc)[0], '^Name:\s*\zs.*')
    endif
    return pname
  endif
  return ''
endfu
fu! s:AttentionMessage(swap_info, pname)
  let statinfo = []
  if executable('stat')
    try
      if !has("bsd")
        " linux / GNU
        let statinfo = systemlist('stat --printf="%U\n%Y\n" '. a:swap_info['fname'])
      else
        " BSD
        let statinfo = systemlist('stat -f "%Su\n%m\n" '. a:swap_info['fname'])
      endif
    " for some reason, it's not possible to read that file, see #74
    catch /^Vim\%((\a\+)\)\=:E484:/
      let statinfo=[]
    endtry
  endif
  let owner = get(statinfo, 0, '')
  let time  = get(statinfo, 1, '')
  return [ 'E325: ATTENTION',
      \   'Found a swap file by the name "'.v:swapname. '"',
      \   "\t". '  owned by: '. owner. '  dated: '. time,
      \   "\t". ' file name: '. a:swap_info['fname'],
      \   "\t". '  modified: '. (a:swap_info['dirty'] ? 'YES' : 'no'),
      \   "\t". ' user name: '. a:swap_info['user']. '  host name: '. a:swap_info['host'],
      \   "\t". 'process ID: '. a:swap_info['pid']. (!empty(a:pname) ? ' ['.a:pname.'] (still running)' : ''),
      \   "\t". 'While opening file "'. a:swap_info['fname']. '"',
      \   "\t". '   dated: '. strftime('%c', a:swap_info['mtime']) ]
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
  if get(g:, 'fencview_autodetect', 0)
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
  let do_modification_check = get(g:, 'RecoverPlugin_Edit_Unmodified', 0)
  let not_modified = 0
  let pname = ''
  let msg = ""
  let bufname = s:isWin() ? fnamemodify(expand('%'), ':p:8') : shellescape(expand('%'))
  let tfile = tempname()
  if s:swapinfo
    let swap_info = swapinfo(v:swapname)
    if has_key(swap_info, 'error')
      " swap file not usable
      echom "Recover.vim: Problem with Swapfile: '". swap_info['error']. "'"
      return 
    endif
    let pid = swap_info['pid']
    let pname = s:PIDName(pid)
    let msg = join(s:AttentionMessage(swap_info, pname), "\n")
    let not_modified = swap_info['dirty'] == 0
  else
    if executable(s:progpath) && !s:isWin() && !s:isMacTerm() && !get(g:, 'RecoverPlugin_No_Check_Swapfile', 0)
      " Doesn't work on windows (system() won't be able to fetch the output)
      " and Mac Terminal (issue #24)  
      " Capture E325 Warning message
      " Leave English output, so parsing will be easier
      " TODO: make it work on windows.
      " if s:isWin()
      "   let wincmd = printf('-c "redir > %s|1d|:q!" ', tfile)
      "   let wincmd = printf('-c "call feedkeys(\"o\n\e:q!\n\")"')
      " endif
      let t = tempname()
      let cmd = printf("%s %s -i NONE -u NONE -es -V0%s %s %s %s",
        \ (s:isWin() ? '' : 'LC_ALL=C'), s:progpath, t,
        \ (!empty(&directory) ? '--cmd ":set directory="' . shellescape(&directory) : ''),
        \ (s:isWin() ? wincmd : ''), bufname)
      call system(cmd)
      let msgl = readfile(t)
      call delete(t)
      let end_of_first_par = match(msgl, "^$", 2) " output starts with empty line: find 2nd one
      let msgl = msgl[1:end_of_first_par] " get relevant part of output
      let msg = join(msgl, "\n")
      let not_modified = (match(msg, "modified: no") > -1)
    endif
    if has("unix") && !empty(msg) && s:is_linux
      " try to get process name from pid
      " This is Linux specific.
      " TODO Is there a portable way to retrive this info for at least unix?
      let pid_pat = 'process ID:\s*\zs\d\+'
      let pid = matchstr(msg, pid_pat)+0
      let pname = s:PIDName(pid)
        let msg = substitute(msg, pid_pat, '& ['.pname."]\n", '')
    endif
  endif
  " Show modification message and present user question about what to do:
  if executable(s:progpath) && executable('diff') "&& s:isWin()
    " Check, whether the files differ issue #7
    " doesn't work on Windows? (cmd is ok, should be executable)
    if s:isWin()
      let tfile = substitute(tfile, '/', '\\', 'g')
    endif
    " disable fenc setting to avoid conversion errors
    let cmd = printf("%s -i NONE -u NONE -N %s -r %s -c ':set fenc=' -c ':w %s|:q!' %s diff %s %s",
      \ s:progpath, (s:isWin() ? '' : '-es'),
      \ (s:isWin() ? fnamemodify(v:swapname, ':p:8') : shellescape(v:swapname)),
      \ tfile, (s:isWin() ? '&' : '&&'),  bufname, tfile)
    call system(cmd)
    " if return code of diff is zero, files are identical
    if !v:shell_error
      " only delete, if the file is not already open in another Vim instance
      let delete = (pname =~? 'vim') ? 0 : 1
    endif
  endif
  if get(g:, 'RecoverPlugin_Delete_Unmodified_Swapfile', 0) && not_modified
    let v:swapchoice = 'd'
    return
  endif
  let prompt_verbose = get(g:, 'RecoverPlugin_Prompt_Verbose', 0)
  if prompt_verbose || (!do_modification_check && !not_modified && (empty(pname) || pname =~? 'vim'))
    echo msg
  endif
  call delete(tfile)
  if delete && !do_modification_check
    echomsg "Swap and on-disk file seem to be identical"
  endif
  let cmd = printf("&Compare\n&Open Read-Only\n&Edit anyway\n&Recover\n&Quit\n&Abort%s",
    \ ( (delete || !empty(msg)) ? "\n&Delete" : ""))
  if !empty(msg)
    let info = 'Please choose: '
  else
    let info = "Swap File '". v:swapname. "' found: "
  endif
  if prompt_verbose || !not_modified
    call inputsave()
    if has("nvim")
      " Force the msg to be drawn for Neovim, fixes
      " https://github.com/chrisbra/Recover.vim/issues/59
      echo msg
    endif
    let p = confirm(info, cmd, (delete ? 7 : 1), 'I')
    call inputrestore()
  elseif not_modified
    let p = 3
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
    if get(g:, 'fencview_autodetect', 0)
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
  call delete(swapname)
  diffoff
  call s:ModifySTL(0)
  exe bufwinnr(curbufnr) " wincmd w"
  call s:SetSwapfile()
  unlet! b:swapname b:did_recovery b:swapbufnr b:swapchoice
endfun
fu! recover#AutoCmdBRP(on) "{{{1
  if a:on && !exists("#SwapBRP")
    augroup SwapBRP
      au! BufNewFile,BufReadPost <buffer> :call s:CheckRecover()
    augroup END
  elseif !a:on && exists('#SwapBRP')
    augroup SwapBRP
      au!
    augroup END
    augroup! SwapBRP
  endif
endfu
" Modeline "{{{1
" vim: fdm=marker fdl=0 ts=2 et sw=0 sts=-1
