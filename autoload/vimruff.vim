" vimruff.vim
" Author:  Pablo Yanez <shaoran@sakuranohana.org>
" Licence: LGPL-2


python3 << PYTHON3

import shlex
import shutil
import sys
import os
import subprocess

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
        set_val("b:vimruff_project_parsed", True)
        return

    possible_vars = ("default", "check-select", "ruff-path")

    for varname in possible_vars:
        if varname in base:
            varname_vim = varname.replace("-", "_")
            set_val(f"b:vimruff_{varname_vim}", base[varname])

    set_val("b:vimruff_project_parsed", True)

def get_cursor_positions(current_buffer):
    cursors = []
    for i, tabpage in enumerate(vim.tabpages):
        if tabpage.valid:
            for j, window in enumerate(tabpage.windows):
                if window.valid and window.buffer == current_buffer:
                    cursors.append((i, j, window.cursor))

    return cursors

def restore_cursors(cursors):
    for i, j, cursor in cursors:
        window = vim.tabpages[i].windows[j]
        try:
            window.cursor = cursor
        except vim.error:
            window.cursor = (len(window.buffer), 0)


def exec_command(command: str, content: str):
    content_s = content.encode("UTF-8")

    cmd = subprocess.Popen(
        shlex.split(command),
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    outs, errs = cmd.communicate(input=content_s)
    out = outs.decode("UTF-8", errors="ignore")
    err = errs.decode("UTF-8", errors="ignore")

    return cmd.returncode, out, err


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


    action = "default"

    if args:
        action = args[0]
        args = args[1:]

    current_buffer = vim.current.window.buffer

    cursors = get_cursor_positions(current_buffer)
    content = "\n".join(current_buffer) + "\n"

    original_content = content

    if action == "check":
        content = ruff_check(bin_path, content, *args)
    elif action == "format":
        content = ruff_format(bin_path, content, *args)
    elif action == "info":
        ruff_info(bin_path)
        return
    elif action == "clear":
        ruff_clear()
        return
    elif action == "default":
        def_cmd = get_config_val("vimruff_default")
        if def_cmd in ("check", "both"):
            content = ruff_check(bin_path, content, *args)

        if def_cmd in ("format", "both"):
            content = ruff_format(bin_path, content, *args)
        else:
            print_error("Invalid default action {def_cmd!r}")
            return
    else:
        print_error(f"Invalid command {action!r}")
        return

    if original_content == content:
        print("vim-ruf: Already formatted")
        return
    else:
        print("vim-ruff: Formatting finished")

    content = content.split("\n")[:-1]


    vim.current.buffer[:] = content

    restore_cursors(cursors)



def ruff_check(bin_path, content, *args):
    select = get_config_val("vimruff_check_select")
    select_opt = ""
    stdin_opt = "-"

    # if the user passed --select in args, use those
    # intead of the values from the config

    if ("--select" not in args) and select:
        # use the passed --select option from the user
        select_opt = "--select " + shlex.quote(select)

    if "-" in args:
        stdin_opt = ""

    cmd = f"{bin_path} check --fix {select_opt} {' '.join(args)} {stdin_opt}"

    _, out, _ = exec_command(cmd, content)

    # 'ruff check --fix -' on error returns the whole input
    # via stdout

    return out

def ruff_format(bin_path, content, *args):
    stdin_opt = "-"

    if "-" in args:
        stdin_opt = ""

    cmd = f"{bin_path} format {' '.join(args)} {stdin_opt}"

    rc, out, err = exec_command(cmd, content)

    # if the command returns with an error, 'ruff format' does not output
    # the original content (like 'ruff check' does)
    if rc == 0:
        return out

    print_error(f"The command {cmd!r} failed with return code {rc}")
    # returnin the original content
    return content

def ruff_info(bin_path):
    lines = []
    lines.append(f"Ruff binary path: {bin_path!r}")
    lines.append(" \nVariables")
    lines.append("=========\n \n")
    lines.append(f"vimruff_default:             {get_config_val('vimruff_default')!r}")
    lines.append(f"vimruff_check_select:        {get_config_val('vimruff_check_select')!r}")
    lines.append(f"vimruff_eval_pyproject_toml: {get_config_val('vimruff_eval_pyproject_toml')!r}")
    lines.append(f"vimruff_project_parsed:      {get_config_val('vimruff_project_parsed')!r}")

    print("\n".join(lines))

def ruff_clear():
    vim.command("unlet! b:vimruff_project_parsed")
    vim.command("unlet! b:vimruff_default")
    vim.command("unlet! b:vimruff_check_select")
    print("Clear finished. Next time you execute a vim-ruff command, pyproject.toml will be parsed again")

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
