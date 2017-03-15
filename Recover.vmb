" Vimball Archiver by Charles E. Campbell
UseVimball
finish
plugin/recover.vim	[[[1
52
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
" vim: fdm=marker fdl=0 ts=2 et sw=0 sts=-1
autoload/recover.vim	[[[1
365
" Vim plugin for diffing when swap file was found
" ---------------------------------------------------------------
" Author: Christian Brabandt <cb@256bit.org>
" Version: 0.19
" Last Change: Thu, 15 Jan 2015 21:26:55 +0100
" Script:  http://www.vim.org/scripts/script.php?script_id=3068
" License: VIM License
" GetLatestVimScripts: 3068 19 :AutoInstall: recover.vim

let s:progpath=(v:version > 704 || (v:version == 704 && has("patch234")) ? v:progpath : 'vim')

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
    let cmd = printf("%s %s -i NONE -u NONE -es -V0%s %s %s",
      \ (s:isWin() ? '' : 'LC_ALL=C'), s:progpath, t,
      \ (s:isWin() ? wincmd : ''), bufname)
    call system(cmd)
    let msgl = readfile(t)
    call delete(t)
    let end_of_first_par = match(msgl, "^$", 2) " output starts with empty line: find 2nd one
    let msgl = msgl[1:end_of_first_par] " get relevant part of output
    let msg = join(msgl, "\n")
    let not_modified = (match(msg, "modified: no") > -1)
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
      if not_modified && pname =~? 'vim'
        let not_modified = 0
      endif
    endif
      if get(g:, 'RecoverPlugin_Delete_Unmodified_Swapfile', 0) && pname !~# 'vim'
        \ && not_modified
        let v:swapchoice = 'd'
        return
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
  if not_modified
    let p = 3
  else
    call inputsave()
    let p = confirm(info, cmd, (delete ? 7 : 1), 'I')
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
doc/recoverPlugin.txt	[[[1
368
*recover.vim*   Show differences for recovered files

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.19 Thu, 15 Jan 2015 21:26:55 +0100
Copyright: (c) 2009, 2010, 2011, 2012, 2013 by Christian Brabandt
           The VIM LICENSE applies to recoverPlugin.vim and recoverPlugin.txt
           (see |copyright|) except use recoverPlugin instead of "Vim".
           NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.


==============================================================================
1. Contents                                                    *RecoverPlugin*

        1.  Contents.....................................: |recoverPlugin|
        2.  recover Manual...............................: |recover-manual|
        3.  recover Feedback.............................: |recover-feedback|
        4.  cvim.........................................: |cvim|
        5.  recover History..............................: |recover-history|

==============================================================================
                                                              *RecoverPlugin-manual*
2. RecoverPlugin Manual                                       *recover-manual*

Functionality

When using |recovery|, it is hard to tell, what has been changed between the
recovered file and the actual on disk version. The aim of this plugin is, to
have an easy way to see differences, between the recovered files and the files
stored on disk.

By default, it will become only active, when a swap file is detected and
enable you to see a diff of the recovered swapfile and the actual file. You
can now use the commands |:RecoveryPluginGet| (to get all differences from the
recovered swapfile) and |:RecoverPluginFinish|(to discard the swapfile
changes) and close the diff mode. Thus those two commands work to easily
discard the changes |:RecoveryPluginFinish| or to recover |:RecoveryPluginGet| 
from the swapfile.

Therefore this plugin sets up an auto command, that will create a diff buffer
between the recovered file and the on-disk version of the same file. You can
easily see, what has been changed and save your recovered work back to the
file on disk.

By default this plugin is enabled. To disable it, use >
    :RecoverPluginDisable
<
To enable this plugin again, use >
    :RecoverPluginEnable
<
When you open a file and vim detects, that an |swap-file| already exists for a
buffer, the plugin presents the default Swap-Exists dialog from Vim adding one
additional option for Diffing (but leaves out the lengthy explanation about
handling Swapfiles that Vim by default shows): >

    Found a swap file by the name "test/normal/.testfile.swp"
            owned by: chrisbra   dated: Wed Nov 28 16:26:42 2012
            file name: ~chrisbra/code/git/vim/Recover/test/normal/testfile
            modified: YES
            user name: chrisbra   host name: R500
            process ID: 4878 [not existing]
    While opening file "test/normal/testfile"
                dated: Tue Nov  6 20:11:55 2012
    Please choose:
    D[i]ff, (O)pen Read-Only, (E)dit anyway, (R)ecover, (Q)uit, (A)bort, (D)elete:


(Note, that additionally, it shows in the process ID row the name of the
process that has the process id or [not existing] if that process doesn't
exist.) Simply use the key, that is highlighted to chose the option. If you
press Ctrl-C, the default dialog of Vim will be shown.

If you have said 'Diff', the plugin opens a new vertical splitt buffer. On the
left side, you'll find the file as it is stored on disk and the right side
will contain your recovered version of the file (using the found swap file).

When you want to keep the version from the swap file, use the command ":FinishRecovery"
to close the diff view and delete the swapfile.

When you want to discard the swap file, use the command ":1,$+1diffget" in the right window,
then close the diff view and delete the swapfile with |:FinishRecovery|. You
can also use the command |:RecoveryPluginGet|, which will automatically
retrieve all changes and finish recovery.

Alternatively you can use the |merge| commands to copy selected content to the buffer
on the right that holds your recovered version. If you are finished, you can close the diff
version and close the window, by issuing |:diffoff!| and |:close| in the
window, that contains the on-disk version of the file. Be sure to save the
recovered version of you file and afterwards you can safely remove the swap
file.
                                        *:RecoverPluginFinish* *:FinishRecovery*
In the recovered buffer, the command >
    :FinishRecovery
<
deletes the swapfile closes the diff window and finishes everything up.

Alternatively you can also use the command >
    :RecoveryPluginFinish
<
                                                        *:RecoverPluginHelp*
The command >
    :RecoverPluginHelp
<
show a small message, on what keys can be used to move to the next different
region and how to merge the changes from one windo into the other.

                                                        *:RecoverPluginGet*
In the recovered buffer, the command >
    :RecoverPluginGet
<
Will get all changes from the recovered swapfile put them in the buffer and
finish diff mode off.

                                                       *RecovePlugin-config*
If you want Vim to automatically edit any file that is open in another Vim
instance but is unmodified there, you need to set the configuration variable:
g:RecoverPlugin_Edit_Unmodified to 1 like this in your |.vimrc| >

    :let g:RecoverPlugin_Edit_Unmodified = 1
<
Note: This only works on Linux.

If you do not want Vim to examine the existing swapfile and figure out things
like whether the file is unmodified in another Vim process and to check the
process id, then you need to set the configuration variable
g:RecoverPlugin_Examine_Swapfile to 1 like this in your |.vimrc| >

    :let g:RecoverPlugin_No_Check_Swapfile = 1
<
If you Vim to silently delete unmodified swapfiles, that are not being edited
in another session, set the variable g:RecoverPlugin_Delete_Unmodified Swapfile
to 1 like this in your |.vimrc| >

    :let g:RecoverPlugin_Delete_Unmodified_Swapfile = 1
<
Note: This only works on Linux.
                                                        *RecoverPlugin-misc*
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
3. CVIM	                                        	            	*cvim*

cvim is a python script (contributed by Marcin Szamotulski) that is
distributed together with the recoverplugin. It is located in the contrib/
folder of the plugin source (or in the contrib/ directory of your $VIMRUNTIME/
path (e.g. usually in ~/.vim/contrib) if you have installed the vimball
version of the plugin)

Usage:

cvim [-h] [-r] [-f] [-a] {directory} ...

    cvim is a python script, which can be used in a terminal to clear the
    {directory} from |swapfile|s.  Without any switches it finds all
    |swapfile|s then checks if a found |swapfile| is used by vim (using psutil
    python library).  If it is not, then it reads the |swapfile| and if the
    content matches the corresponding file it delets it.  You can get psutil
    from:
	http://code.google.com/p/psutil/

    If a file has multiple |swapfile|s left you can exit vim with |:cq| to
    preserve them all on disk or you will be asked to delete them/step through
    them.  These |swapfile|s are sorted by their modification time stamp
    (newest first).

    |cvim| works with python2.6, 2.7 and python3.3.

    The scripts accepts the following positional arguments:
    {directory}         directory where to look for swap (by default current
			directory), it can be specified multiple times.

    optional arguments:
    -h, --help           show help message and exit
    -r, -R, --recursive  search directory recursively
    -f, --find           only find and list |swapfile|s, it impiles -r
    -a, --ask            ask before deleting swap files which do not differ from
			 the file.

Note: cvim might not work on Windows.
==============================================================================
4. Plugin Feedback                                        *recover-feedback*

Feedback is always welcome. If you like the plugin, please rate it at the
vim-page:
http://www.vim.org/scripts/script.php?script_id=3068

You can also follow the development of the plugin at github:
http://github.com/chrisbra/Recover.vim

Please don't hesitate to report any bugs to the maintainer, mentioned in the
third line of this document.

==============================================================================
5. recover History                                          *recover-history*

0.20: (unreleased)
- Several fixes for |cvim|
  (contributed by Mateusz Jończyk,
  https://github.com/chrisbra/Recover.vim/pull/35, thanks!)
- Don't assume vim when parsing Swap file dialog
  (contributed by Michael Reed, 
  https://github.com/chrisbra/Recover.vim/pull/36, thanks!)
- Check for existence of |v:progpath| before using it (reported by 
  Dmytro Kolomoiets, https://github.com/chrisbra/Recover.vim/issues/37,
  thanks!)
- Fix issue #38 (https://github.com/chrisbra/Recover.vim/issues/38, reported
  by PhilRunninger, thanks!)
- If g:RecoverPlugin_Delete_Unmodified_Swapfile is set, delete unmodifed
  swapfiles that are not edited in another Vim buffer.
  (https://github.com/chrisbra/Recover.vim/issues/46, reported by Astara,
  thanks!)

0.19: Jan 15, 2015 "{{{1
- fix issue 29 (plugin always loaded autoload part, 
  https://github.com/chrisbra/Recover.vim/issues/29,
  reported by Justin Keyes, thanks!)
- fix issue 30 (remove needless 2 second sleep,
  https://github.com/chrisbra/Recover.vim/issues/30,
  reported by Justin Keyes, thanks!)
- only reset swapfile option, if the current buffer has a name
- |:RecoverPluginGet| to easily get the recovered version into your buffer and
  finish everything up (issue 31 https://github.com/chrisbra/Recover.vim/issues/31,
  reported by luxigo, thanks!)

0.18: Aug 14, 2013 "{{{1

- fix issue 19 (https://github.com/chrisbra/Recover.vim/issues/19, by
  replacing feedkeys("...\n") by feedkeys("...\<cr>", reported by vlmarek,
  thanks!)
- fix issue 20 (https://github.com/chrisbra/Recover.vim/issues/20,
  (let vim automatically edit a file, that is unmodified in another vim
  instance, suggested by rking, thanks!)
- merge issue 21 (https://github.com/chrisbra/Recover.vim/pull/21, create more
  usefule README.md file, contribted by Shubham Rao, thanks!)
- merge issue 22 (https://github.com/chrisbra/Recover.vim/pull/22, delete BufReadPost autocommand
  contributed by Marcin Szamotulski, thanks!)
- distribute |cvim| script (contributed by Marcin Szamotulski, thanks!)

0.17: Feb 16, 2013 "{{{1

- fix issue 17 (https://github.com/chrisbra/Recover.vim/issues/17 patch by
  lyokha, thanks!)
- Use default key combinations in the dialog of the normal Vim dialog (adding
  only the Diff option)
- Make sure, the process ID is shown

0.16: Nov 21, 2012 "{{{1

- Recovery did not work, when original file did not exists (issue 11
  https://github.com/chrisbra/Recover.vim/issues/11
  reported by Rking, thanks!)
- By default, delete swapfile, if no differences found (issue 15
  https://github.com/chrisbra/Recover.vim/issues/15
  reported by Rking, thanks!)
- reset 'swapfile' option, so that Vim by default creates .swp files
  (idea and patch by Marcin Szamotulski, thanks!)
- capture and display |E325| message (and also try to figure out the name of
  the pid (issue 12 https://github.com/chrisbra/Recover.vim/issues/12)

0.15: Aug 20, 2012 "{{{1

- fix issue 5 (https://github.com/chrisbra/Recover.vim/issues/5 patch by
  lyokha, thanks!)
- CheckSwapFileExists() hangs, when a swap file was not found, make sure,
  s:Swapname() returns a valid file name
- fix issue 6 (https://github.com/chrisbra/Recover.vim/issues/6 patch by
  lyokha, thanks!)
- Avoid recursive :redir call (https://github.com/chrisbra/Recover.vim/pull/8
  patch by Ingo Karkat, thanks!)
- Do not set 'bexpr' for unrelated buffers (
  https://github.com/chrisbra/Recover.vim/pull/9 patch by Ingo Karkat,
  thanks!)
- Avoid aborting the diff (https://github.com/chrisbra/Recover.vim/pull/10
  patch by Ingo Karkat, thanks!)
- Allow to directly delete the swapfile (
  https://github.com/chrisbra/Recover.vim/issues/7 suggested by jgandt,
  thanks!)

0.14: Mar 31, 2012 "{{{1

- still some problems with issue #4

0.13: Mar 29, 2012 "{{{1

- fix issue 3 (https://github.com/chrisbra/Recover.vim/issues/3 reported by
  lyokha, thanks!)
- Ask the user to delete the swapfile (issue
  https://github.com/chrisbra/Recover.vim/issues/4 reported by lyokha,
  thanks!)

0.12: Mar 25, 2012 "{{{1

- minor documentation update
- delete swap files, if no difference found (issue
  https://github.com/chrisbra/Recover.vim/issues/1 reported by y, thanks!)
- fix some small issues, that prevented the development versions from working
  (https://github.com/chrisbra/Recover.vim/issues/2 reported by Rahul Kumar,
  thanks!)

0.11: Oct 19, 2010 "{{{1

- use confirm() instead of inputdialog() (suggested by D.Fishburn, thanks!)

0.9: Jun 02, 2010 "{{{1

- use feedkeys(...,'t') instead of feedkeys() (this works more reliable,
  although it pollutes the history), so delete those spurious history entries
- |RecoverPluginHelp| shows a small help message, about diff commands
  (suggested by David Fishburn, thanks!)
- |RecoverPluginFinish| is a shortcut for |FinishRecovery|

0.8: Jun 01, 2010 "{{{1

- make :FinishRecovery more robust

0.7: Jun 01, 2010 "{{{1

- |FinishRecovery| closes the diff-window and cleans everything up (suggestion
  by David Fishburn)
- DeleteSwapFile is not needed anymore

0.6: May 31, 2010 "{{{1

- |recover-feedback|
- Ask to really open a diff buffer for a file (suggestion: David Fishburn,
  thanks!)
- DeleteSwapFile to delete the swap file, that was used to create the diff
  buffer
- change feedkeys(...,'t') to feedkeys('..') so that not every command appears
  in the history.

0.5: May 04, 2010 "{{{1

- 0r command in recover plugin adds extra \n
  Patch by Sergey Khorev (Thanks!)
- generate help file with 'et' set, so the README at github looks prettier

0.4: Apr 26, 2010 "{{{1

- handle Windows and Unix path differently
- Code cleanup
- Enabled |:GLVS|

0.3: Apr 20, 2010 "{{{1

- first public verion
- put plugin on a public repository
  (http://github.com/chrisbra/Recover.vim)

0.2: Apr 18, 2010 "{{{1

- Internal version, some cleanup, bugfixes for windows

0.1: Apr 17, 2010 "{{{1

- Internal version, First working version, using simple commands

==============================================================================
Modeline: "{{{1
vim:tw=78:ts=8:ft=help:et:fdm=marker:fdl=0:norl
contrib/cvim	[[[1
390
#!/usr/bin/env python
# -%- coding: utf-8 -%-
# Author: Marcin Szamotulski
# Python Versions: 2.7, 3.4
# License: VIM LICENSE.
#          NO WARRANTY, EXPRESS OR IMPLIED> USE AT-YOUR-OWN-RISK.

import os
import sys
import re
import subprocess
import argparse
import locale
import psutil
import heapq
import tempfile
import time
from copy import copy
from collections import defaultdict
from operator import attrgetter
PY3 = sys.version_info[0] == 3
if not PY3:
    input = raw_input
encoding = locale.getpreferredencoding()
if PY3:
    from functools import reduce
    unicode = str
else:
    bytes = str

EDITOR = u'gvim' if \
    re.search(
        r'gvim(\.exe)?$',
        os.environ.get('EDITOR', 'vim')) \
    else 'vim'
CURDIR = os.path.normpath(os.path.abspath(os.curdir))


def format_path(path):
    return u"%s%s" % (os.curdir, path[len(CURDIR):]) \
        if path.startswith(CURDIR) \
        else path


class StdOut(object):
    """
    Support for Python2.6
    """

    def __getattr__(self, name):

        return getattr(sys.__stdout__, name)


    def write(self, s):
        if sys.stdout.isatty():
            default_encoding = sys.stdout.encoding
        else:
            default_encoding = locale.getpreferredencoding()

        if isinstance(s, unicode):
            s = s.encode(default_encoding)
        if isinstance(s, bytes):
            s = s.decode(default_encoding)
        sys.__stdout__.write(s)


sys.stdout = StdOut()


class SwapDecodeError(Exception):
    pass


class File(object):
    """
    Class holding a file corresponding to a Swap instance.
    """

    def __init__(self, swap):
        self.path = swap.file_name
        self.swap = swap

    @property
    def content(self):
        if hasattr(self, '_content'):
            return self._content
        try:
            if PY3:
                mode = 'br'
            else:
                mode = 'r'
            with open(self.path, mode) as fo:
                cont = fo.read()
        except Exception:
            cont = None
        self._content = cont
        return cont


class Swap(object):
    """
    Class describing and introducing method related to a swap file.
    """

    def __init__(self, swap):

        dirp = os.path.dirname(swap)
        base = os.path.basename(swap)
        if PY3:
            self._swap = swap
            self.swap = swap
        else:
            self._swap = swap
            self.swap = swap.decode(encoding)
        file_name, self.swapext = os.path.splitext(base)
        try:
            self.mtime = os.path.getmtime(self.swap)
        except os.error:
            self.mtime = None
        if sys.platform == 'linux2' and not PY3 or \
                sys.platform == 'linux' and PY3:
            file_name = file_name[1:]
        else:
            # TODO: shortname option on MS-DOS machines
            # :help :swapname
            pass
        self.file_name = os.path.join(dirp, file_name)
        self.file = File(self)

    def __lt__(self, other):

        if self.file_name != other.file_name:
            return self.file_name < other.file_name
        if self.mtime is not None and other.mtime is not None:
            # the newest first
            return self.mtime > other.mtime
        elif self.mtime is not None:
            return False
        else:
            return True

    __ne__ = lambda s, o: s != o
    __gt__ = lambda s, o: not s < o and s != o

    def __eq__(self, other):

        return self.swap == other.swap

    def __str__(self):
        return self._swap

    def __unicode__(self):
        return self.swap

    if PY3:
        __str__ = __unicode__
        del __unicode__

    def check(self):
        """
        check if swap file is used by a process
        """

        for process in psutil.process_iter():
            try:
                files = process.get_open_files()
            except psutil.AccessDenied:
                files = []
            except psutil.error.NoSuchProcess:
                files = []
            files = map(attrgetter('path'), files)
            if not PY3:
                files = map(lambda p: p.decode(encoding), files)
            if self.swap in files:
                return process

    def read_swap(self):
        """
        Read a swap file into self._content.  Use NamedTemporaryFile.
        """

        tfile = tempfile.NamedTemporaryFile()
        name = tfile.name
        cmd = u'{0} -X -u NONE -r -c"w! {1}|q" "{2}"'.format(EDITOR, name, self.swap)
        exit = subprocess.call(cmd, shell=True)
        if exit != os.EX_OK:
            e = SwapDecodeError(swap.swap)
            e.exit = exit
            raise e
        self._content = tfile.read()
        tfile.close()

    def remove(self):
        """
        Delete the swap file.
        """
        if os.path.exists(self.swap):
            os.remove(self.swap)
            self.removed = True

    @property
    def content(self):
        """
        Return content of the swap file.
        """

        if hasattr(self, '_content'):
            return self._content
        else:
            self.read_swap()
            return self._content

    @property
    def is_modified(self):
        """
        Check if swap file differs from self.file.
        """

        return self.content != self.file.content

    def format(self):

        sname = format_path(self.swap)
        if self.mtime:
            return u'{0} ({1})'.format(
                sname,
                time.strftime('%x %X', time.localtime(self.mtime))
            )
        else:
            return sname


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument(
        dest='directories',
        nargs='*',
        default=(os.curdir,),
        help='directory where to look for swap (by default current directory)',
    )
    parser.add_argument(
        '-r', '-R', '--recursive',
        dest='recursive',
        action='store_true',
        help='search directory recursively'
    )
    parser.add_argument(
        '-f', '--find',
        dest='find',
        action='store_true',
        help='only find swap files, it impiles -r',
    )
    parser.add_argument(
        '-a', '--ask',
        dest='ask',
        action='store_true',
        help='ask before deleting any swap files.'
    )
    args = parser.parse_args(sys.argv[1:])
    if not hasattr(args, 'directories'):
        setattr(args, 'directories', [os.path.abspath(os.curdir)])

    if args.find:
        args.recursive = True

    swaps = defaultdict(list)
    _swaps = []

    # Note: also find .swf files
    swap_re = re.compile('(\.[^/]+)?\.sw[a-z]+$')
    for dir_ in args.directories:
        if args.recursive:
            os.chdir(os.path.abspath(dir_))
            for dirp, dirs, fns in os.walk(os.curdir):
                for f in fns:
                    if swap_re.search(f):
                        swap = Swap(os.path.abspath(os.path.join(dirp, f)))
                        heapq.heappush(swaps[swap.file_name], swap)

        else:
            os.chdir(os.path.abspath(dir_))
            _swaps = filter(lambda f: swap_re.search(f), os.listdir(os.curdir))
            if not PY3:
                _swaps = map(lambda s: s.decode(encoding), _swaps)
            for sp in _swaps:
                swap = Swap(sp)
                heapq.heappush(swaps[swap.file_name], swap)

    del _swaps
    os.chdir(CURDIR)

    if swaps:
        nr_swaps = reduce(lambda x, y: x + y, map(len, swaps.values()))
    else:
        nr_swaps = 0

    if nr_swaps == 0:
        print(u'No swap files found.')
        sys.exit(os.EX_OK)
    elif nr_swaps == 1:
        print(u'Found: {0} swap file (mtime):'.format(unicode(nr_swaps)))
    else:
        print(u'Found: {0} swap files (mtime):'.format(unicode(nr_swaps)))
    if not PY3:
        _CURDIR = CURDIR.decode(encoding)
    else:
        _CURDIR = CURDIR
    for p, sws in swaps.items():
        sws = copy(sws)
        while sws:
            swap = heapq.heappop(sws)
            print(u'  {0}'.format(swap.format()))
    if args.find:
        sys.exit(os.EX_OK)

    # main loop
    for file_name in swaps.keys():
        sws = swaps[file_name]
        len_sws = len(sws)
        if len_sws > 1:
            print(u"Multiple swap files for \"{0}\" (exit {1} with :cq to keep the "
                  u"remaining ones)".format(format_path(swap.file_name), EDITOR))
        delete = False
        while sws:
            # pop the youngest swap files first
            swap = heapq.heappop(sws)
            process = swap.check()
            if process:
                if process.terminal:
                    terminal = u" on %s" % process.terminal.decode('utf-8')
                else:
                    terminal = u""
                print(u'The "{0}" swap file is used by process {1} ({2}){3}.  '
                      u'Skipping.'.format(swap, unicode(process.pid),
                                          process.name.decode(encoding),
                                          terminal))
                continue

            try:
                swap.read_swap()
            except SwapDecodeError as e:
                print(u'Skipping {0}: {1} exited with error code {2}'.format(swap, EDITOR, unicode(e.exit)))
                continue

            if not swap.is_modified:
                if args.ask:
                    inp = input('The swap file "{0}" and "{1}" have the same content.'
                                ' Do you want to delete "{0}"?  [Y/N]\n'
                                .format(os.path.basename(swap._swap),
                                        os.path.basename(swap.file_name))
                                )
                    inp = inp.lower()
                    if inp in ('y', 'yes'):
                        swap.remove()
                    else:
                        print('Skipping removal')
                else:
                    print(u'Deleting "{0}" swap file (matching the content)'
                          .format(swap))
                    swap.remove()
            else:
                if len_sws > 1:
                    # b:swapname is set for :FinishRecovery
                    cmd = u'{0} -X +"call recover#DiffRecoveredFile()|let b:swapname=\'{1}\'" -r "{1}"'. \
                        format(EDITOR, swap)
                else:
                    cmd = u'{0} -X "{1}"'.format(EDITOR, swap.file_name)
                print(u'\n{0}'.format(cmd))
                vim = subprocess.Popen(cmd, shell=True)
                if vim.wait() != 0:
                    break
                elif len_sws > 1 and sws:
                    inp = input('There are more swap files for "{0}", do'
                                ' you want to delete them all? [Y/N]'.
                                format(format_path(swap.file_name)))
                    if inp.lower() in ('y', 'yes'):
                        swap.remove()
                        delete = True
                        break
                    else:
                        print('Skipping removal')
        if delete and sws:
            print(u'Deleting swap files:')
            for swap in sws:
                print(u'\t{0}'.format(format_path(swap.swap)))
                swap.remove()

    sys.exit(os.EX_OK)
