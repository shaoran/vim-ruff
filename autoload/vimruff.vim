" vimruff.vim
" Author:  Pablo Yanez <shaoran@sakuranohana.org>
" Licence: LGPL-2


python3 << PYTHON3

import shlex
import shutil
import sys
import os

from pathlib import Path

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


def print_error(msg, hl="ErrorMsg"):
    msg = shlex.quote(msg)
    vim.command(f"echohl {hl}")
    vim.command(f"echo {msg}")
    vim.command("echohl Null")

def get_val(name):
    if not int(vim.eval(f"exists(\"{name}\")")):
        raise ValueError("not found")
    return vim.eval(name)

def set_val(name, val):
    if isinstance(val, str):
        vval = shlex.quote(val)
        if val == vval:
            val = f"'{val}'"
        else:
            val = vval
    elif isinstance(val, bool):
        if val == True:
            val = "v:true"
        else:
            val = "v:false"
    vim.command(f"let {name}={val}")

def ruff(*args):
    try:
        bin_path = get_val("g:vimruff_ruff_path")

        if not os.path.exists(bin_path):
            print_error(f"The path {bin_path!r} does not exist")
            return

        if not os.access(bin_path, os.X_OK):
            print_error(f"The path {bin_path!r} is not an executable")
            return
    except ValueError:
        bin_path = shutil.which("ruff")
        if bin_path is None:
            print_error("ruff is not found in the PATH environment variable.\nEither update your PATH or set g:vimruff_ruff_path")
            return

    print("This is ruff", args)

PYTHON3

function vimruff#Ruf(...)
    :py3 ruff(*vim.eval("a:000"))
endfunction


function vimruff#RuffComplete(ArgLead, CmdLine, CursorPos)
py3 << EOF
_res = ruff_cmdline_complete(vim.eval("a:ArgLead"), vim.eval("a:CmdLine"), vim.eval("a:CursorPos"))

vim.command(f"let comp = {_res!r}")
EOF

    return comp
endfunction
