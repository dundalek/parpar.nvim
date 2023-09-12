# ParPar = Parinfer + Paredit

ParPar is a Neovim plugin that blends [Parinfer](https://shaunlebron.github.io/parinfer/) and [Paredit](https://calva.io/paredit/) modes together for the best lisp editing experience.

It combines best of both, ease of use of Parinfer and extra power of advanced Paredit operations.

It works by integrating [nvim-parinfer](https://github.com/gpanders/nvim-parinfer) and [nvim-paredit](https://github.com/julienvincent/nvim-paredit) plugins and making them play well together.

## Install

Using [lazy.nvim](https://github.com/folke/lazy.nvim) and default paredit bindings:

```lua
{
  "dundalek/parpar.nvim",
  dependencies = { "gpanders/nvim-parinfer", "julienvincent/nvim-paredit" },
  opts = { }
},
```

## Setup

You can customize [paredit options](https://github.com/julienvincent/nvim-paredit#configuration) and add custom bindings which are automatically wrapped to work with parinfer:

```lua
{
  "dundalek/parpar.nvim",
  dependencies = { "gpanders/nvim-parinfer", "julienvincent/nvim-paredit" },
  config = function()
    local paredit = require("nvim-paredit")
    require("parpar").setup {
      paredit = {
        -- pass any nvim-paredit options here
        keys = {
          -- custom bindings are automatically wrapped
          ["<A-H>"] = { paredit.api.slurp_backwards, "Slurp backwards" },
          ["<A-J>"] = { paredit.api.barf_backwards, "Barf backwards" },
          ["<A-K>"] = { paredit.api.barf_forwards, "Barf forwards" },
          ["<A-L>"] = { paredit.api.slurp_forwards, "Slurp forwards" },
        }
      }
    }
  end
},
```

If you need extra control you can also manually wrap callback functions with `parpar.wrap()`:

```lua
local parpar = require("parpar")
require("nvim-paredit").setup {
  keys = {
    ["<A-H>"] = { parpar.wrap(paredit.api.slurp_backwards), "Slurp backwards" },
    ["<A-J>"] = { parpar.wrap(paredit.api.barf_backwards), "Barf backwards" },
    ["<A-K>"] = { parpar.wrap(paredit.api.barf_forwards), "Barf forwards" },
    ["<A-L>"] = { parpar.wrap(paredit.api.slurp_forwards), "Slurp forwards" },
  }
}
```

#### Slurp/Barf Mnemonic

The custom bindings example above binds <kbd>Alt</kbd>+<kbd>Shift</kbd> with <kbd>H</kbd>, <kbd>J</kbd>, <kbd>K</kbd>, <kbd>L</kbd> to slurp/barf actions.
These are based on original [vim-sexp](https://github.com/guns/vim-sexp) bindings. Figuring out whether to tirgger slurp or barf and in which direction can be confusing, but there is a simple mnemonic.

It helps to imagine the parentheses are placed between keys.  
The H, J keys manipulate opening parenthesis (left) and K, L manipulate closing parenthesis (right). Then for example opening parenthesis H moves it to the left, J to the right. 

```
 (      )
🠤 🠦   🠤 🠦
H J    K L
```

#### Using with AI completion plugins

Parinfer can interfere with AI completion plugins like Copilot or [Codeium](https://codeium.com). Here is an example how to make parinfer work with the [codeium.vim](https://github.com/Exafunction/codeium.vim) plugin. It uses `parpar.pause()` to pause parinfer, then accept the completion and finally resume parinfer asynchronously using a callback to `vim.schedule()`.

```lua
{
  "Exafunction/codeium.vim",
  dependencies = { "dundalek/parpar.nvim" },
  init = function()
    vim.g.codeium_disable_bindings = 1
  end,
  config = function()
    local parpar = require("parpar")
    local accept = function()
      vim.schedule(parpar.pause())
      return vim.fn["codeium#Accept"]()
    end

    vim.keymap.set("i", "<Tab>", accept, { expr = true })
  end
},
```

## How it works

The plugin is a thin wrapper over paredit actions:

1. Temporarily disable parinfer.  
   *Avoids parinfer interfering with the following paredit action.*
2. Perform the paredit action.
3. Enable parinfer again and re-run in paren mode.  
   *This corrects the indentation to make sure it ends up consistent.*
