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


command! Ruff :call vimruff#Ruf()
