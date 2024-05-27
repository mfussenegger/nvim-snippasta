# `snippasta`

A plugin that allows you to paste code as snippet, based on [treesitter queries][treesitter-queries]
which identify parts of the code that should be replaced with tabstops.

[See demo](https://social.fussenegger.pro/system/media_attachments/files/112/500/794/132/998/267/original/872f1784ca082a69.mp4)

## Installation

Requires nvim-0.10+

```bash
git clone \
    https://github.com/mfussenegger/nvim-snippasta.git \
    ~/.config/nvim/pack/plugins/start/nvim-snippasta
```

## Usage

The plugin exposes a single function which you can call via `keymap`:

```lua
keymap.set({"n"}, "<leader>p", function() require("snippasta").paste() end)
```

The function tries to translate the text present in the `v:register` `register`
into a snippet by replacing parts of it with tabstops and expand it using
`vim.snippet.expand`.

To identify which parts of the text are converted to tabstops it uses
tree-sitter queries containing `@tabstop` captures.

The queries themselves are _not_ part of the plugin. You have to add them yourself.
They're likely opinionated and I don't have the bandwidth to maintain a
collection of them for each language.

To add the queries, create query files named `tabstop.scm` in the query folder.
(`~/.config/nvim/queries/<language>`). Read `:help treesitter-query` for more
information.

## Query examples

Here are a few examples to give you some inspiration.
You can use `:InspectTree` and `:EditQuery` to help you write your own queries.

### lua

```query
(variable_declaration
  (assignment_statement
    (variable_list
        name: (identifier) @tabstop)
    ))

(table_constructor
  (field
    name: _
    value: _ @tabstop))


(function_call
  name: _
  arguments: (arguments (_) @tabstop))
```


### python

```query
(assignment
  left: (identifier) @tabstop)

(call
  arguments: (argument_list [
    (keyword_argument
      value: (_) @tabstop)
    (string) @tabstop
    (integer) @tabstop
    (true) @tabstop
    (false) @tabstop
  ]))
```


### xml

```query
(content
  (CharData) @tabstop)
```


[treesitter-queries]: https://tree-sitter.github.io/tree-sitter/using-parsers#query-syntax
