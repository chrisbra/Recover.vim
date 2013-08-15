Recover
======
> Show differences for recovered files

When editing files with Vim and one trips about existing swap files, it is hard to tell, what has been changed between the swap file and the actual on disk version. The aim of this plugin is, to have an easy way to see differences, between the swap files and the files stored on disk.

Therefore this plugin sets up an auto command, that will create a diff buffer between the recovered file and the on-disk version of the same file. You can easily see, what has been changed and save your recovered work back to the file on disk.

By default this plugin is enabled. To disable it, use `:RecoverPluginDisable`
To enable this plugin again, use `:RecoverPluginEnable`

When you open a file and vim detects, that an swap-file already exists for a buffer, the plugin presents the default Swap-Exists dialog from Vim adding one additional option for Diffing (but leaves out the lengthy explanation about handling Swapfiles that Vim by default shows):

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

Note, that additionally, it shows in the process ID row of the process having opened that file or [not existing] if that process doesn't exist.) Simply use the key, that is highlighted to chose the option. If you press Ctrl-C, the default dialog of Vim will be shown.

If you have said 'Diff', the plugin opens a new vertical splitt buffer. On the left side, you'll find the file as it is stored on disk and the right side will contain your recovered version of the file (using the found swap file).

You can now use the usual merge commands to copy the contents to the buffer that holds your recovered version. If you are finished, you can close the diff version and close the window, by issuing `:diffoff!` and `:close` in the window, that contains the on-disk version of the file. Be sure to save the recovered version of your file and afterwards you can safely remove the swap file.

In the recovered window, the command `:FinishRecovery` deletes the swapfile closes the diff window and finishes everything up. Alternatively you can also use the command `:RecoveryPluginFinish`

The command `:RecoverPluginHelp` show a small message, on what keys can be used to move to the next different region and how to merge the changes from one windo into the other.

If your Vim was built with `+balloon_eval`, recover.vim will also set up an balloon expression, that shows you, which buffer contains the recovered version of your file and which buffer contains the unmodified on-disk version of your file, if you move the mouse of the buffer.

If you have setup your `statusline`, recover.vim will also inject some info (which buffer contains the on-disk version and which buffer contains the modified, recovered version). Additionally the buffer that is read-only, will have a filename  of something like `original file (on disk-version)`. If you want to save that version, use :saveas.

Installation
---

Use the plugin manager of your choice. Or download the [stable][] or [unstable][] version of the plugin, edit it with Vim (`vim Recover.vmb`) and simply source it (`:so %`). Restart and take a look at the help (`:h RecoverPlugin`)

[unstable]: https://github.com/chrisbra/Recover.vim
[stable]: http://www.vim.org/scripts/script.php?script_id=3068

Usage
---
Once installed, take a look at the help at `:h RecoverPlugin-manual`

License & Copyright
-------

The Vim License applies. See `:h license`
© 2009 - 2013 by Christian Brabandt

__NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK__
