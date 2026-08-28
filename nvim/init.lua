-- ==========================================================================
-- Neovim Configuration — init.lua
-- ==========================================================================
-- A single-file config for an experienced developer coming from IntelliJ.
-- Supports: Go, Python, Java/Kotlin, TypeScript/JavaScript, Rust
--
-- PREREQUISITES (install these before launching Neovim):
--   1. Neovim >= 0.11 (https://github.com/neovim/neovim/releases)
--   2. A Nerd Font for icons (e.g., JetBrainsMono Nerd Font)
--      https://www.nerdfonts.com/
--   3. ripgrep — for Telescope live grep
--      brew install ripgrep  /  apt install ripgrep
--   4. fd — for Telescope file finder
--      brew install fd  /  apt install fd-find
--   5. Language toolchains you want to work with:
--      - Go:    go (gopls installed automatically by Mason)
--      - Python: python3, pip
--      - Java:  JDK 17+ (JAVA_HOME set)
--      - Kotlin: kotlin compiler (optional, LSP handles most things)
--      - Node:  node, npm (for TypeScript/JS tooling)
--      - Rust:  rustup (rust-analyzer installed automatically by Mason)
--
-- INSTALLATION:
--   mkdir -p ~/.config/nvim
--   cp init.lua ~/.config/nvim/init.lua
--   nvim                          # lazy.nvim bootstraps on first launch
--   :checkhealth                  # verify everything is wired up
--
-- STRUCTURE OF THIS FILE:
--   1. Bootstrap (lazy.nvim package manager)
--   2. Core options (the stuff you'd set in IntelliJ preferences)
--   3. Keymaps (leader key, navigation, common actions)
--   4. Plugin specs (each plugin is one table with inline config)
--   5. LSP configuration (vim.lsp.config — the new Neovim 0.11+ way)
--   6. Autocommands (filetype-specific tweaks)
-- ==========================================================================


-- ==========================================================================
-- 1. BOOTSTRAP — lazy.nvim (package manager)
-- ==========================================================================
-- lazy.nvim auto-installs itself on first run. You never need to touch this.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)


-- ==========================================================================
-- 2. CORE OPTIONS
-- ==========================================================================
-- These are the Neovim equivalents of IntelliJ editor preferences.

-- Leader key — <Space> is the most ergonomic choice. Almost all custom
-- keymaps below start with <leader>. Set this BEFORE loading plugins.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Line numbers: absolute + relative. Relative numbers make Vim motions
-- like `12j` or `5k` trivial — you can see exactly how many lines away
-- your target is. This is one of the biggest "aha" moments from IntelliJ→Vim.
vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation — 4 spaces, like IntelliJ defaults for Java/Go.
-- Individual filetypes override this below (e.g., 2 spaces for JS/TS).
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Search: case-insensitive unless you type an uppercase letter.
-- Same as IntelliJ's "Match case" being off by default.
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true       -- highlight matches
vim.opt.incsearch = true      -- search as you type

-- UI
vim.opt.termguicolors = true  -- 24-bit color (your terminal must support it)
vim.opt.signcolumn = "yes"    -- always show the sign column (git, diagnostics)
vim.opt.cursorline = true     -- highlight the line your cursor is on
vim.opt.scrolloff = 8         -- keep 8 lines visible above/below cursor
vim.opt.sidescrolloff = 8
vim.opt.wrap = false          -- no line wrapping (like IntelliJ default)
vim.opt.colorcolumn = "120"   -- subtle column guide at 120 chars

-- Splits: open new splits to the right/below (more natural)
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Undo: persistent undo across sessions. This is a superpower — you can
-- undo changes from yesterday. IntelliJ has Local History; this is Vim's.
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- Decrease update time for snappier UI (default is 4000ms)
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300      -- faster keymap sequence completion

-- Clipboard: use system clipboard. Yank in Neovim, paste in browser.
-- Same as IntelliJ's default behavior.
vim.opt.clipboard = "unnamedplus"

-- Show substitution preview in a split (`:s/foo/bar/` shows live preview)
vim.opt.inccommand = "split"

-- Disable the mouse in normal mode. Controversial, but it forces you
-- to learn Vim motions. Remove this line if you want mouse support.
-- vim.opt.mouse = ""

-- Completion menu
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.pumheight = 15        -- max items in completion popup


-- ==========================================================================
-- 3. KEYMAPS — Core (non-plugin) keymaps
-- ==========================================================================
-- Philosophy: <leader> prefix for project-level actions (find file, grep,
-- git). No-leader for editing motions. This mirrors how IntelliJ uses
-- Cmd/Ctrl for project actions and raw keys for editing.

local map = vim.keymap.set

-- Clear search highlight with Escape (you'll do this constantly)
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Better window navigation — Ctrl+hjkl to move between splits.
-- In IntelliJ you'd use Cmd+Shift+[ ] or mouse. This is faster.
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to below split" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to above split" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

-- Resize splits with Ctrl+arrows
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Move selected lines up/down in visual mode (like Alt+Up/Down in IntelliJ)
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered when scrolling half-pages
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })

-- Keep cursor centered when jumping through search results
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- Paste over selection without losing your clipboard content.
-- In Vim, pasting over a selection replaces your register with the deleted
-- text. This preserves it — more intuitive, like IntelliJ paste behavior.
map("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting register" })

-- Quick save
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })

-- Close buffer without closing the window/split
map("n", "<leader>q", "<cmd>bd<CR>", { desc = "Close buffer" })

-- Diagnostic navigation (errors, warnings) — like F2/Shift+F2 in IntelliJ
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic message" })


-- ==========================================================================
-- 4. PLUGINS
-- ==========================================================================
-- Each plugin is a table in the list below. lazy.nvim handles installation,
-- loading, and updating. Run :Lazy to see the UI.

require("lazy").setup({

  -- ========================================================================
  -- COLORSCHEME — Catppuccin
  -- ========================================================================
  -- A well-maintained theme with great Treesitter/LSP highlight support.
  -- Alternatives worth trying: tokyonight, gruvbox-material, kanagawa
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000, -- load before other plugins so colors are available
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- darkest variant. Try "latte" for light theme.
        integrations = {
          cmp = true,
          gitsigns = true,
          treesitter = true,
          mason = true,
          telescope = { enabled = true },
          which_key = true,
          indent_blankline = { enabled = true },
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

{
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    require("nvim-tree").setup()
    vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })
  end,
},

  -- ========================================================================
  -- TELESCOPE — Fuzzy finder (like IntelliJ's Ctrl+Shift+N / Cmd+Shift+O)
  -- ========================================================================
  -- The single most important plugin. This replaces:
  --   - Find File (Ctrl+Shift+N)     → <leader>ff
  --   - Find in Files (Ctrl+Shift+F) → <leader>fg
  --   - Recent Files                 → <leader>fr
  --   - Go to Symbol                 → <leader>fs
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Native FZF sorter for ~100x faster filtering on large repos
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          -- Ignore build artifacts and deps. Customize to your repo layout.
          file_ignore_patterns = {
            "node_modules", ".git/", "target/", "build/", "dist/",
            "%.class", "%.jar", "%.pyc", "__pycache__",
          },
          -- Layout: dropdown works well on wide monitors
          layout_strategy = "horizontal",
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
        },
      })
      telescope.load_extension("fzf")

      local builtin = require("telescope.builtin")
      map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      map("n", "<leader>fg", builtin.live_grep, { desc = "Find in files (grep)" })
      map("n", "<leader>fb", builtin.buffers, { desc = "Find open buffers" })
      map("n", "<leader>fh", builtin.help_tags, { desc = "Search help" })
      map("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
      map("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Document symbols" })
      map("n", "<leader>fS", builtin.lsp_workspace_symbols, { desc = "Workspace symbols" })
      map("n", "<leader>fd", builtin.diagnostics, { desc = "All diagnostics" })
      map("n", "<leader>fw", builtin.grep_string, { desc = "Find word under cursor" })
    end,
  },

  -- ========================================================================
  -- TREESITTER — Syntax highlighting and code understanding
  -- ========================================================================
  -- Treesitter parses your code into an AST, giving you:
  --   - Accurate syntax highlighting (way better than regex-based)
  --   - Smart text objects (select a function, a class, a parameter)
  --   - Incremental selection (expand/shrink selection by AST node)
  -- Think of it as IntelliJ's PSI tree but for highlighting/selection.
  --
  -- NOTE: nvim-treesitter was rewritten in 2025 (main branch).
  --   - require("nvim-treesitter.configs").setup is GONE
  --   - highlight/indent are now enabled via Neovim core APIs
  --   - ensure_installed uses require("nvim-treesitter").install()
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        -- Install parsers to the standard data directory
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      -- Install parsers for your core languages (no-op if already installed)
      local parsers = {
        -- Your core languages
        "go", "gomod", "gosum", "gowork",
        "python",
        "java", "kotlin",
        "javascript", "typescript", "tsx", "html", "css", "json",
        "rust", "toml",
        -- Infrastructure / config you'll encounter daily
        "lua", "vim", "vimdoc",
        "yaml", "dockerfile", "bash", "sql",
        "markdown", "markdown_inline",
        "hcl",       -- Terraform
        "make",
      }
      -- Install missing parsers asynchronously on startup
      vim.schedule(function()
        require("nvim-treesitter").install(parsers)
      end)

      -- Enable treesitter highlighting and indentation for all filetypes.
      -- On the new main branch, you must explicitly call vim.treesitter.start()
      -- and set indentexpr — the plugin no longer does this for you.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
        callback = function(args)
          -- Only start treesitter if a parser exists for this filetype
          pcall(vim.treesitter.start, args.buf)
          -- Use treesitter-based indentation
          if pcall(vim.treesitter.get_parser, args.buf) then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- Treesitter text objects: lets you do things like `daf` (delete a function),
  -- `vac` (select a class), `cia` (change inside argument/parameter).
  -- Also provides jumping between functions/classes — like IntelliJ's Alt+Up/Down.
  --
  -- NOTE: Must use branch = "main" to match nvim-treesitter main branch.
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local ts_select = require("nvim-treesitter-textobjects.select")
      local ts_move = require("nvim-treesitter-textobjects.move")

      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
        },
        move = {
          enable = true,
          set_jumps = true,
        },
      })

      -- Select text objects
      local select_maps = {
        ["af"] = { query = "@function.outer", desc = "Select outer function" },
        ["if"] = { query = "@function.inner", desc = "Select inner function" },
        ["ac"] = { query = "@class.outer", desc = "Select outer class" },
        ["ic"] = { query = "@class.inner", desc = "Select inner class" },
        ["aa"] = { query = "@parameter.outer", desc = "Select outer argument" },
        ["ia"] = { query = "@parameter.inner", desc = "Select inner argument" },
      }
      for key, mapping in pairs(select_maps) do
        vim.keymap.set({ "x", "o" }, key, function()
          ts_select.select_textobject(mapping.query, "textobjects")
        end, { desc = mapping.desc })
      end

      -- Move between functions/classes
      local move_maps = {
        { key = "]f", query = "@function.outer", method = "goto_next_start", desc = "Next function start" },
        { key = "]c", query = "@class.outer", method = "goto_next_start", desc = "Next class start" },
        { key = "[f", query = "@function.outer", method = "goto_previous_start", desc = "Prev function start" },
        { key = "[c", query = "@class.outer", method = "goto_previous_start", desc = "Prev class start" },
      }
      for _, m in ipairs(move_maps) do
        vim.keymap.set({ "n", "x", "o" }, m.key, function()
          ts_move[m.method](m.query, "textobjects")
        end, { desc = m.desc })
      end
    end,
  },

  -- ========================================================================
  -- LSP — Language Server Protocol
  -- ========================================================================
  -- This is the big one. LSP gives you IntelliJ-level intelligence:
  --   - Go to definition, find references, rename symbol
  --   - Hover docs, signature help, code actions
  --   - Diagnostics (errors, warnings) in real time
  --
  -- Since Neovim 0.11+, LSP config uses the native vim.lsp.config() API.
  -- mason.nvim auto-installs the language servers.
  -- mason-lspconfig auto-enables installed servers via vim.lsp.enable().
  -- nvim-lspconfig provides the default server configurations (as data).

  -- Mason: manages external tool installation (LSP servers, formatters, etc.)
  {
    "mason-org/mason.nvim",
    config = function()
      require("mason").setup({
        ui = { border = "rounded" },
      })
    end,
  },

  -- Bridge: auto-install LSP servers and auto-enable them
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        -- These servers will be auto-installed on first launch.
        ensure_installed = {
          "gopls",             -- Go
          "pyright",           -- Python (fast type-checker, Microsoft)
          "jdtls",             -- Java (Eclipse JDT.LS — same engine as VS Code Java)
          "kotlin_language_server", -- Kotlin
          "ts_ls",             -- TypeScript/JavaScript
          "rust_analyzer",     -- Rust
          "lua_ls",            -- Lua (for editing this very config file!)
          "dockerls",          -- Dockerfile
          "yamlls",            -- YAML (for k8s manifests, CI configs, etc.)
          "bashls",            -- Bash/Shell
          "jsonls",            -- JSON
          "html",              -- HTML
          "cssls",             -- CSS
        },
        -- Automatically call vim.lsp.enable() for all Mason-installed servers.
        -- NOTE: kotlin_language_server is excluded because its nvim-lspconfig
        -- root_dir function triggers a vim.fs.abspath assertion on Neovim 0.12
        -- when called during startup without a valid buffer context.
        -- We call vim.lsp.enable() for it separately below (after its
        -- vim.lsp.config block), which safely registers a FileType autocmd
        -- so root_dir resolution only happens when a .kt file is opened.
        automatic_enable = {
          exclude = { "kotlin_language_server" },
        },
      })
    end,
  },

  -- nvim-lspconfig: provides default server configs (data-only, not a framework)
  {
    "neovim/nvim-lspconfig",
    lazy = true, -- loaded as a dependency; configs are in its lsp/ directory
    dependencies = {
      -- Useful status indicator for LSP progress (shows in statusline)
      { "j-hui/fidget.nvim", opts = {} },
    },
  },

  -- ========================================================================
  -- COMPLETION — nvim-cmp
  -- ========================================================================
  -- Auto-completion engine. Sources: LSP, buffer text, file paths, snippets.
  -- Tab/Shift-Tab to navigate, Enter to confirm (similar to IntelliJ).
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",      -- LSP completions
      "hrsh7th/cmp-buffer",         -- words from current buffer
      "hrsh7th/cmp-path",           -- file paths
      "L3MON4D3/LuaSnip",          -- snippet engine
      "saadparwaiz1/cmp_luasnip",   -- snippet completions
      "rafamadriz/friendly-snippets", -- community snippet collection
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Load VS Code-style snippets (the friendly-snippets collection)
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          -- Navigate completion menu
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),

          -- Scroll docs in the preview window
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),

          -- Trigger completion manually (usually auto-triggers)
          ["<C-Space>"] = cmp.mapping.complete(),

          -- Confirm selection — only confirm explicitly selected items
          ["<CR>"] = cmp.mapping.confirm({ select = false }),

          -- Tab: if completion menu is open, navigate. If in a snippet,
          -- jump to next placeholder. Otherwise, insert a tab.
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),

        -- Source priority: LSP > snippets > buffer > paths
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip", priority = 750 },
          { name = "buffer", priority = 500 },
          { name = "path", priority = 250 },
        }),

        -- Formatting: show source and kind icons
        formatting = {
          format = function(entry, vim_item)
            local source_names = {
              nvim_lsp = "[LSP]",
              luasnip = "[Snip]",
              buffer = "[Buf]",
              path = "[Path]",
            }
            vim_item.menu = source_names[entry.source.name] or ""
            return vim_item
          end,
        },
      })
    end,
  },

  -- ========================================================================
  -- GIT — Gitsigns (inline git info, like IntelliJ's gutter annotations)
  -- ========================================================================
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "│" },
          change       = { text = "│" },
          delete       = { text = "▁" },
          topdelete    = { text = "▔" },
          changedelete = { text = "~" },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local bopts = function(desc)
            return { buffer = bufnr, desc = "Git: " .. desc }
          end

          -- Navigation between hunks (changed blocks)
          map("n", "]h", gs.next_hunk, bopts("Next hunk"))
          map("n", "[h", gs.prev_hunk, bopts("Prev hunk"))

          -- Actions
          map("n", "<leader>hs", gs.stage_hunk, bopts("Stage hunk"))
          map("n", "<leader>hr", gs.reset_hunk, bopts("Reset hunk"))
          map("n", "<leader>hp", gs.preview_hunk, bopts("Preview hunk"))
          map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, bopts("Blame line"))
          map("n", "<leader>hd", gs.diffthis, bopts("Diff against index"))
        end,
      })
    end,
  },

  -- ========================================================================
  -- FILE EXPLORER — Neo-tree (like IntelliJ's Project tool window)
  -- ========================================================================
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        filesystem = {
          follow_current_file = { enabled = true }, -- auto-reveal current file
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = true,
          },
        },
      })
      map("n", "<leader>t", "<cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" })
      map("n", "<leader>o", "<cmd>Neotree reveal<CR>", { desc = "Reveal file in explorer" })
    end,
  },

  -- ========================================================================
  -- STATUSLINE — Lualine
  -- ========================================================================
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "catppuccin",
          section_separators = "",       -- clean, no arrows
          component_separators = "│",
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff" },
          lualine_c = { { "filename", path = 1 } }, -- show relative path
          lualine_x = { "diagnostics" },
          lualine_y = { "filetype" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- ========================================================================
  -- WHICH-KEY — Keybinding discovery (no IntelliJ equivalent, you'll love it)
  -- ========================================================================
  -- Press <leader> and wait — a popup shows all available keybindings.
  -- Invaluable while you're learning.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({ delay = 300 })
      -- Register group labels for the leader menu
      wk.add({
        { "<leader>f", group = "Find (Telescope)" },
        { "<leader>h", group = "Git hunks" },
        { "<leader>c", group = "Code actions" },
        { "<leader>r", group = "Refactor" },
      })
    end,
  },

  -- ========================================================================
  -- QUALITY OF LIFE
  -- ========================================================================

  -- Auto-pair brackets, quotes, etc. (like IntelliJ's auto-pairing)
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
      -- Integrate with nvim-cmp so CR confirms completion AND adds pairs
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- Comment toggling — `gcc` to toggle line, `gc` in visual mode
  -- (like Ctrl+/ in IntelliJ)
  { "numToStr/Comment.nvim", opts = {} },

  -- Indent guides (like IntelliJ's indent guides)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = { char = "│" },
      scope = { enabled = true, show_start = false, show_end = false },
    },
  },

  -- Surround: add/change/delete surrounding characters
  -- `ysiw"` → surround word with quotes, `cs"'` → change " to ', `ds"` → delete "
  -- One of those Vim superpowers that doesn't exist in IntelliJ.
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  -- Highlight TODO/FIXME/HACK comments
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },

}, {
  -- lazy.nvim options
  checker = { enabled = true, notify = false }, -- auto-check for plugin updates
  change_detection = { notify = false },
})


-- ==========================================================================
-- 5. LSP CONFIGURATION — vim.lsp.config (Neovim 0.11+ native API)
-- ==========================================================================
-- With the new API, you call vim.lsp.config() to set per-server options.
-- mason-lspconfig.nvim automatically calls vim.lsp.enable() for installed
-- servers, so you do NOT need to call it yourself.
--
-- nvim-lspconfig (the plugin) still provides the *default* configs for each
-- server via its lsp/ directory on the runtimepath. vim.lsp.config() here
-- MERGES with those defaults — you only need to specify your overrides.

-- Global defaults for ALL LSP servers
vim.lsp.config("*", {
  -- Enhanced capabilities from nvim-cmp for completion
  capabilities = (function()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local has_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if has_cmp then
      capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
    end
    return capabilities
  end)(),
})

-- LSP keymaps — set up when any LSP server attaches to a buffer.
-- These map closely to IntelliJ equivalents:
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(event)
    local buf = event.buf
    local opts = function(desc)
      return { buffer = buf, desc = "LSP: " .. desc }
    end

    -- Navigation (IntelliJ equivalents noted)
    map("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))             -- Ctrl+B
    map("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
    map("n", "gr", vim.lsp.buf.references, opts("Find references"))               -- Alt+F7
    map("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))      -- Ctrl+Alt+B
    map("n", "gt", vim.lsp.buf.type_definition, opts("Go to type definition"))    -- Ctrl+Shift+B

    -- Information
    map("n", "K", vim.lsp.buf.hover, opts("Hover docs"))                         -- Ctrl+Q
    map("n", "<leader>k", vim.lsp.buf.signature_help, opts("Signature help"))     -- Ctrl+P
    map("i", "<C-k>", vim.lsp.buf.signature_help, opts("Signature help"))

    -- Refactoring (the stuff you'll miss most from IntelliJ)
    map("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename symbol"))             -- Shift+F6
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("Code action")) -- Alt+Enter
    map("n", "<leader>cf", function()
      vim.lsp.buf.format({ async = true })
    end, opts("Format file"))                                                      -- Ctrl+Alt+L
  end,
})

-- ------------------------------------------------------------------
-- Go — gopls
-- ------------------------------------------------------------------
-- gopls is excellent out of the box. These settings enable
-- auto-imports (like IntelliJ's optimize imports on save).
vim.lsp.config("gopls", {
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        shadow = true,
        nilness = true,
        unusedwrite = true,
      },
      staticcheck = true,    -- extra linting
      gofumpt = true,        -- stricter formatting than gofmt
      usePlaceholders = true, -- show parameter names in completions
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
})

-- ------------------------------------------------------------------
-- Python — Pyright
-- ------------------------------------------------------------------
vim.lsp.config("pyright", {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",   -- "strict" if you want full typing
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})

-- ------------------------------------------------------------------
-- Java — jdtls
-- ------------------------------------------------------------------
-- NOTE: For heavy Java work, consider nvim-jdtls plugin by mfussenegger
-- which adds debugging, test runner, and project import. This basic
-- setup gives you navigation, completion, and diagnostics.
vim.lsp.config("jdtls", {
  -- jdtls requires a workspace directory per project
  cmd = {
    "jdtls",
    "-data", vim.fn.expand("~/.cache/jdtls-workspace/") .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
  },
})

-- ------------------------------------------------------------------
-- Kotlin
-- ------------------------------------------------------------------
-- Override root_dir with root_markers to avoid the nvim-lspconfig
-- kotlin_language_server config's eager vim.fs.root() call, which
-- crashes on Neovim 0.12 during startup (no buffer context yet).
-- root_markers achieves the same root detection but is handled
-- safely by Neovim's internal LSP machinery.
vim.lsp.config("kotlin_language_server", {
  root_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "pom.xml", ".git" },
})

-- Defer enable to FileType so a buffer exists when root_dir resolves.
-- nvim-lspconfig's default root_dir function calls vim.fs.root() eagerly,
-- which asserts in Neovim 0.12 if no buffer context exists yet.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "kotlin",
  once = true,
  callback = function()
    vim.lsp.enable("kotlin_language_server")
  end,
})

-- ------------------------------------------------------------------
-- TypeScript / JavaScript — ts_ls
-- ------------------------------------------------------------------
vim.lsp.config("ts_ls", {
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
      },
    },
  },
})

-- ------------------------------------------------------------------
-- Rust — rust-analyzer
-- ------------------------------------------------------------------
-- rust-analyzer is arguably the best LSP server in existence.
vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = {
        command = "clippy",   -- run clippy instead of check (more lints)
      },
      cargo = {
        allFeatures = true,  -- enable all Cargo features
      },
      inlayHints = {
        enable = true,
        typeHints = { enable = true },
        parameterHints = { enable = true },
        chainingHints = { enable = true },
      },
    },
  },
})

-- ------------------------------------------------------------------
-- Lua — for editing Neovim config
-- ------------------------------------------------------------------
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
      telemetry = { enable = false },
    },
  },
})

-- ------------------------------------------------------------------
-- Infrastructure languages — minimal config, defaults are fine
-- ------------------------------------------------------------------
-- These don't need per-server overrides; nvim-lspconfig defaults +
-- mason-lspconfig's automatic_enable handles them.
vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      schemas = {
        -- Add your commonly-used schemas here. Examples:
        -- ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        -- ["https://json.schemastore.org/kustomization.json"] = "kustomization.yaml",
      },
      validate = true,
    },
  },
})

-- ------------------------------------------------------------------
-- Diagnostics appearance
-- ------------------------------------------------------------------
vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = "●" },
  signs = true,
  underline = true,
  update_in_insert = false, -- don't distract while typing
  severity_sort = true,
  float = { border = "rounded", source = true },
})

-- Diagnostic signs in the gutter (customize the icons)
local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end


-- ==========================================================================
-- 6. AUTOCOMMANDS — Filetype-specific settings
-- ==========================================================================

local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- Go: format + organize imports on save using gopls
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = "*.go",
  callback = function()
    -- Organize imports (like IntelliJ's optimize imports)
    local params = vim.lsp.util.make_range_params()
    params.context = { only = { "source.organizeImports" } }
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
    for _, res in pairs(result or {}) do
      for _, action in pairs(res.result or {}) do
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
        elseif action.command then
          vim.lsp.buf.execute_command(action.command)
        end
      end
    end
    -- Format
    vim.lsp.buf.format({ async = false })
  end,
})

-- Rust: format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = "*.rs",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- Python: format on save (if LSP supports it)
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = "*.py",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- JS/TS/JSON: 2-space indentation (industry convention)
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "javascript", "typescript", "typescriptreact", "javascriptreact", "json", "html", "css", "yaml" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
  end,
})

-- Highlight yanked text briefly (visual feedback for yank operations)
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})


-- ==========================================================================
-- CHEAT SHEET — Keep this around until you've internalized the keymaps
-- ==========================================================================
--
-- NAVIGATION (Normal mode):
--   <leader>ff    Find files           (IntelliJ: Ctrl+Shift+N)
--   <leader>fg    Grep in files        (IntelliJ: Ctrl+Shift+F)
--   <leader>fb    Open buffers         (IntelliJ: Ctrl+E)
--   <leader>fr    Recent files         (IntelliJ: recent files)
--   <leader>t     Toggle file tree     (IntelliJ: Alt+1)
--   <leader>o     Reveal in file tree  (IntelliJ: scroll from source)
--
-- LSP (Normal mode):
--   gd            Go to definition     (IntelliJ: Ctrl+B)
--   gr            Find references      (IntelliJ: Alt+F7)
--   gi            Go to implementation (IntelliJ: Ctrl+Alt+B)
--   K             Hover docs           (IntelliJ: Ctrl+Q)
--   <leader>rn    Rename symbol        (IntelliJ: Shift+F6)
--   <leader>ca    Code action          (IntelliJ: Alt+Enter)
--   <leader>cf    Format file          (IntelliJ: Ctrl+Alt+L)
--   [d / ]d       Prev/Next diagnostic (IntelliJ: F2 / Shift+F2)
--
-- GIT:
--   ]h / [h       Next/Prev hunk
--   <leader>hp    Preview hunk
--   <leader>hs    Stage hunk
--   <leader>hr    Reset hunk
--   <leader>hb    Blame line
--
-- EDITING:
--   gcc           Toggle comment line  (IntelliJ: Ctrl+/)
--   gc            Toggle comment (visual)
--   <CR>          Expand selection      (IntelliJ: Ctrl+W)  [see note below]
--   <BS>          Shrink selection      (IntelliJ: Ctrl+Shift+W)  [see note below]
--   ysiw"         Surround word with "
--   cs"'          Change " to '
--   ds"           Delete surrounding "
--
-- NOTE: Incremental selection (<CR>/<BS>) was removed in the treesitter
-- rewrite. Use visual mode + text objects (vaf, vac, etc.) instead.
--
-- GENERAL:
--   <leader>w     Save file
--   <leader>q     Close buffer
--   <C-h/j/k/l>  Navigate splits
--   <leader>      Wait... which-key shows all options!
-- ==========================================================================
