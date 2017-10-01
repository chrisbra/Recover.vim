# Recover.vim adds a diff option when Vim finds a swap file

When you open a file in Vim but it was already open in another instance or not
closed properly in a past edit, Vim will warn you, but it won't show you what
the difference is between the hidden swap file and the regular saved file. Of
all the actions you might want to do, the most obvious one is missing: see a
diff.

## Installation

We recommend installing with a plugin manager (there are several).

Alternatively, download the plugin (either the [stable][] or [unstable][]
version), edit it with Vim (`vim Recover.vmb`), then source it (`:so %`), and
finally restart Vim. You can check successful installation by opening the help
file (`:h RecoverPlugin`).

[unstable]: https://github.com/chrisbra/Recover.vim
[stable]: http://www.vim.org/scripts/script.php?script_id=3068

## How to use

Recover.vim adds a new first entry to the list of actions, like this:

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

**Notice that the `D[i]ff` option means pressing `i` and not `D`!**
(unfortunately, D is already claimed by Delete, and we can't use R for Remove
because that's claimed by Recover)

Also, in the case that an active process has the swap file open, Recover.vim
adds the relevant process ID to the dialog to make that easier to find.

If you choose the new `D[i]ff` option, you'll see a vertical split buffer. On
the left side, you'll see the file as it is stored on disk. On the right side,
you'll see the diff from the recovered swap file.

You can then use the usual Vim merge commands if you want to copy the contents
from the swap buffer. When you are finished, you can close the diff version and
close the window, by issuing `:diffoff!` and `:close` in the window that
contains the on-disk version of the file. Be sure to save the recovered version
of your file.

To delete the no-longer-needed swap file when in the recovered window, use the
command `:FinishRecovery`. That will delete the swapfile, close the diff window,
and end the diff/merge process. Alternatively, you can use the command
`:RecoveryPluginFinish`.

The command `:RecoverPluginHelp` show a small message on what keys can be used
to move to the next different region and how to merge the changes from one
window into the other.

If your Vim was built with `+balloon_eval`, Recover.vim will also set up an
balloon expression that shows you which buffer contains the recovered version of
your file and which buffer contains the unmodified on-disk version of your file,
if you move the mouse of the buffer.

If you have setup your `statusline`, Recover.vim will also inject some info
about which buffer contains the on-disk version and which buffer contains the
modified, recovered version. Additionally, the read-only buffer will have a
filename  of something like `original file (on disk-version)`. If you want to
save that version, use :saveas.

Get more help via `:h RecoverPlugin-manual`

## How to enable or disable Recover.vim

Once installed, Recover.vim is enabled by default.. To disable it, use
`:RecoverPluginDisable`. To enable it again, use `:RecoverPluginEnable`.

When enabled, you can also do a one-time skip of the Recover.vim dialog with
Ctrl-C. Then, the default Vim dialog (without the D[i]ff option) will be shown.


License & Copyright
-------

The Vim License applies. See `:h license`
© 2009 - 2017 by Christian Brabandt

__NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK__
