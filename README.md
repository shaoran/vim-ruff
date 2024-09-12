# vim-ruff

A simple VIM plugin for [Ruff][1]

## Motivation: Why does this even exist at all?

Ruff has already great integration with VIM via [ALE][2] and [CoC][3].
But for that you also need to configure those plugins, select a LSP
and if you make an error, it's difficult to figure out what went wrong and
your VIM might not be usable unless you fix the errors. I don't want to
deal with that.

This plugin has been heavily inspired by [Black][4]'s plugin and Black's plugin
does not need any special configuration, no LSPs, etc. You just install the plugin
and you do `:Black`. I wanted something like this for Ruff, install the plugin
and just do `:Ruff`.

TODO: write the next sections



[1]: https://github.com/astral-sh/ruff
[2]: https://github.com/dense-analysis/ale
[3]: https://github.com/neoclide/coc.nvim
[4]: https://github.com/psf/black
