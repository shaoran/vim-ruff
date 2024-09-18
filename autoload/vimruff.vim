" vimruff.vim
" Author:  Pablo Yanez <shaoran@sakuranohana.org>
" Licence: LGPL-2


python3 << PYTHON3

import shlex
import shutil
import sys
import os

from pathlib import Path

RUFF_COMMANDS = ["check", "format", "info", "clear"]

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

    pos1_vals = RUFF_COMMANDS

    if len(opts) == 1:
        return pos1_vals

    if len(opts) == 2:
        return match_all_startswith(pos1_vals, arg_lead)

    # second argument is full, nothing left to complete
    return []


def print_error(msg, hl="ErrorMsg"):
    msg = repr(msg)
    vim.command(f"echohl {hl}")
    vim.command(f"echo {msg}")
    vim.command("echohl Null")

def get_val(name):
    if not int(vim.eval(f"exists(\"{name}\")")):
        raise ValueError("not found")
    return vim.eval(name)

def set_val(name, val):
    if isinstance(val, str):
        val = repr(val)
    elif isinstance(val, bool):
        if val == True:
            val = "v:true"
        else:
            val = "v:false"
    vim.command(f"let {name}={val}")

def get_config_val(name):
    """
    The difference of this functin to get_val is that this
    function checks first for the buffer variables. The variable
    name should not have a prefix like g: or b:
    """

    try:
        return get_val(f"b:{name}")
    except ValueError:
        pass

    return get_val(f"g:{name}")


def find_pyproject_toml(path, max_rec=1024):
    fn_dir = path
    while True:
        max_rec -= 1
        if max_rec == 0:
            raise KeyError("pyproject.toml not found")

        fn_dir = os.path.dirname(fn_dir)

        fn = os.path.join(fn_dir, "pyproject.toml")

        if os.path.exists(fn):
            return fn

        if fn_dir == os.sep:
            raise KeyError("pyproject.toml not found")


def parse_pyproject_toml():
    cwd = os.getcwd()
    buff_fn = vim.eval("expand('%')")
    if (buff_fn is None) or (buff_fn == ""):
        buff_fn = "__dummy__.py"
    if os.path.isabs(buff_fn):
        fn_path = buff_fn
    else:
        fn_path = os.path.join(cwd, buff_fn)

    fn_path = str(Path(fn_path).resolve())

    try:
        pyproject_fn = find_pyproject_toml(fn_path)
    except KeyError:
        # file not found
        set_val("b:vimruff_project_parsed", True)
        return

    try:
        import tomllib
    except ImportError:
        try:
            import tomli as tomllib
        except ImportError:
            set_val("b:vimruff_project_parsed", True)
            print_error(f"Neither tomllib nor tomli are found. Unable to parse\n{pyproject_fn!r}", "WarningMsg")
            return

    try:
        with open(pyproject_fn, "rb") as fp:
            config = tomllib.load(fp)
    except:
        set_val("b:vimruff_project_parsed", True)
        print_error(f"Error parsing {pyproject_fn!r}", "WarningMsg")
        return

    try:
        base = config["tool"]["vimruff"]["config"]
    except KeyError:
        pass

    possible_vars = ("default", "check-select")

    for varname in possible_vars:
        if varname in base:
            varname_vim = varname.replace("-", "_")
            set_val(f"b:vimruff_{varname_vim}", base[varname])

    set_val("b:vimruff_project_parsed", True)

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

    check_pyproject = get_val("g:vimruff_eval_pyproject_toml")
    if check_pyproject:
        try:
            get_val("b:vimruff_project_parsed")
        except ValueError:
            parse_pyproject_toml()

    # if pyproject.toml has been parsed and contained
    # the variables, they have been set via b:<var>

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
