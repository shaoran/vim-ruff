" ruff.vim
" Author:  Pablo Yanez <shaoran@sakuranohana.org>
" Licence: LGPL-2

if exists("g:vimruff_loaded")
    finish
endif

if v:version < 700 || !has('python3')
    func! __INVALID_VERSION()
        echo "The vim-ruff plugin requires vim7.0+ with Python 3.6 support."
    endfunc
    command! Ruff :call __INVALID_VERSION()
    finish
endif

let g:vimruff_loaded = "loaded"

" default values for global variables
if !exists("g:vimruff_default")
    let g:vimruff_default = "format"
endif

if !exists("g:vimruff_check_select")
    let g:vimruff_check_select = ""
endif

if !exists("g:vimruff_eval_pyproject_toml")
    let g:vimruff_eval_pyproject_toml = v:true
endif

function RuffComplete(ArgLead, CmdLine, CursorPos)
    return call vimruff#RuffComplete(a:ArgLead, a:CmdLine, a:CursorPos)
endfunction

command! -nargs=* -complete=customlist,vimruff#RuffComplete Ruff call vimruff#Ruf(<f-args>)
