" vimruff.vim
" Author:  Pablo Yanez <shaoran@sakuranohana.org>
" Licence: LGPL-2


python3 << PYTHON3

import shlex

def match_all_startswith(options, candidate):
    if candidate == "":
        return []

    matches = []
    for opt in options:
        if opt.startswith(candidate):
            matches.append(opt)

    return matches

def ruff_cmdline_complete(arg_lead, cmd_line, cursor_pos):
    # shlex.split takes care of multiple empty spaces, tabs and quotes
    opts = shlex.split(cmd_line)
    assert(len(opts) > 0)
    assert(opts[0] == "Ruff")

    pos1_vals = ["check", "format", "info"]

    if len(opts) == 1:
        return pos1_vals

    if len(opts) == 2:
        return match_all_startswith(pos1_vals, arg_lead)

    # second argument is full, nothing left to complete
    return []


def print_error(msg):
    msg = shlex.quote(msg)
    vim.command("echohl ErrorMsg")
    vim.command(f"echo {msg}")
    vim.command("echohl Null")

def get_val(name):
    if not int(vim.eval(f"exists(\"{name}\")")):
        raise ValueError("not found")
    return vim.eval(name)

def ruff():
    print("This is ruff")

PYTHON3

function vimruff#Ruf(...)
    :py3 ruff()
endfunction


function vimruff#RuffComplete(ArgLead, CmdLine, CursorPos)
py3 << EOF
_res = ruff_cmdline_complete(vim.eval("a:ArgLead"), vim.eval("a:CmdLine"), vim.eval("a:CursorPos"))

vim.command(f"let comp = {_res!r}")
EOF

    return comp
endfunction
