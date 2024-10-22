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


## Installation and usage

### Installation

To install with [vim-plug][1]:

Add to your configuration:

```
Plug 'shaoran/vim-ruff'
```

and execute `:PlugInstall`.


### Configuration

The following variables can be specified:

| Variable | Default value | Description |
|:----|:----|:----|
| `g:vimruff_ruff_path` | - | Path to the `ruff` binary |
| `g:vimruff_default` | `"format"` | The default command |
| `g:vimruff_check_select` | - | `--select` argument for `ruff check` |
| `g:vimruff_eval_pyproject_toml` | `v:true` | Evaluate the `pyproject.toml` file |


#### `g:vimruff_ruff_path`

Path to the `ruff` binary. If this variable is not set, then the `PATH`
environment variable is evaluated to find the path to the `ruff` binary.

#### `g:vimruff_default`

The `:Ruff` command supports the `format` and `check` commands. This variable
sets the default command to execute when `:Ruff` without arguments.

The values for this variable are:

- `"format"`
- `"check"`
- `"both"` (first `check --fix` is executed and then `format`)


#### `g:vimruff_check_select`

The `--select` argument for `ruff check --fix`

#### `g:vimruff_eval_pyproject_toml`

If set then this plugin will evaluate the `pyproject.toml` file (relative
to the current buffer). You can use the `pyproject.toml` file to override
`g:vimruff_default`, `g:vimruff_check_select` and `g:vimruff_ruff_path`
variables. This allows you to have different settings per project.

Example:

```toml
[tool.vimruff.config]
default = "both"
check-select = "I"
ruff-path = "/opt/tools/ruff"
```


### Usage

TODO: write me


[1]: https://github.com/astral-sh/ruff
[2]: https://github.com/dense-analysis/ale
[3]: https://github.com/neoclide/coc.nvim
[4]: https://github.com/psf/black
[5]: https://github.com/junegunn/vim-plug
