" vimruff.vim
" Author:  Pablo Yanez <shaoran@sakuranohana.org>
" Licence: LGPL-2


python3 << PYTHON3

def ruff():
    print("This is ruff")

PYTHON3

function vimruff#Ruf(...)
    :py3 ruff()
endfunction
