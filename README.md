*recover.vim*   Show differences for recovered files

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.17 Sat, 16 Feb 2013 23:04:09 +0100
Copyright: (c) 2009, 2010 by Christian Brabandt         
           The VIM LICENSE applies to recoverPlugin.vim and recoverPlugin.txt
           (see |copyright|) except use recoverPlugin instead of "Vim".
           NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.


==============================================================================
1. Contents                                                    *recoverPlugin*

        1.  Contents.....................................: |recoverPlugin|
        2.  recover Manual...............................: |recover-manual|
        3.  recover Feedback.............................: |recover-feedback|
        4.  recover History..............................: |recover-history|

==============================================================================
2. RecoverPlugin Manual                                       *recover-manual*

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

You can now use the |merge| commands to copy the contents to the buffer that
holds your recovered version. If you are finished, you can close the diff
version and close the window, by issuing |:diffoff!| and |:close| in the
window, that contains the on-disk version of the file. Be sure to save the
recovered version of you file and afterwards you can safely remove the swap
file.
                                        *RecoverPluginFinish* *FinishRecovery*
In the recovered window, the command >
    :FinishRecovery
<
deletes the swapfile closes the diff window and finishes everything up.

Alternatively you can also use the command >
    :RecoveryPluginFinish
<

                                                        *RecoverPluginHelp*
The command >
    :RecoverPluginHelp
<
show a small message, on what keys can be used to move to the next different
region and how to merge the changes from one windo into the other.

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
3. Plugin Feedback                                        *recover-feedback*

Feedback is always welcome. If you like the plugin, please rate it at the
vim-page:
http://www.vim.org/scripts/script.php?script_id=3068

You can also follow the development of the plugin at github:
http://github.com/chrisbra/Recover.vim

Please don't hesitate to report any bugs to the maintainer, mentioned in the
third line of this document.

==============================================================================
4. recover History                                          *recover-history*

0.17 Feb 16, 2013 "{{{1
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
