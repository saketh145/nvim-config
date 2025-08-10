-- init.lua

-- ========== BOOTSTRAP lazy.nvim ==========
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ========== ENSURE MASON BIN IS FIRST IN PATH ==========
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin;" .. vim.env.PATH

-- ========== PLUGIN SETUP ==========
require('lazy').setup({

  -- File search & fuzzy finder
  { "nvim-telescope/telescope.nvim", tag = "0.1.4", dependencies = { "nvim-lua/plenary.nvim" } },

  -- LSP
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },

  -- Autocompletion & snippets
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },

  -- Syntax highlighting with Treesitter
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- Git integration
  { "lewis6991/gitsigns.nvim" },

  -- File explorer
  { "nvim-tree/nvim-tree.lua" },

  -- Statusline
  { "nvim-lualine/lualine.nvim" },

  -- Color scheme
  { "folke/tokyonight.nvim" },

  -- Indentation guides
  { "lukas-reineke/indent-blankline.nvim" },

  -- Which-key helper
  { "folke/which-key.nvim" },

  -- Autopairs for brackets
  { "windwp/nvim-autopairs" },

  -- Commenting
  { "numToStr/Comment.nvim" },

  -- Java LSP plugin
  { "mfussenegger/nvim-jdtls" },

  -- Rust-enhanced LSP tooling
  {
    "simrat39/rust-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "mfussenegger/nvim-dap" },
    config = function()
      require("rust-tools").setup({
        server = {
          capabilities = require("cmp_nvim_lsp").default_capabilities(),
        },
      })
    end,
  },

  -- Vim motions practice games
  {
    "ThePrimeagen/vim-be-good",
    cmd = "VimBeGood",
  },
  {
    "szymonwilczek/vim-be-better",
    cmd = "VimBeBetter",
  },


})

-- ========== BASIC OPTIONS & KEYMAPS ==========
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.mouse = 'a'

-- ========== COLORSHEME ==========
vim.cmd.colorscheme("tokyonight")

-- ========== TREESITTER COMPILER SETTINGS ==========
require('nvim-treesitter.install').prefer_git = false
require('nvim-treesitter.install').compilers = { "gcc", "clang" }

-- ========== TREESITTER SETUP ==========
require('nvim-treesitter.configs').setup {
  ensure_installed = {
    "lua", "python", "typescript", "javascript", "html", "css",
    "c", "cpp", "rust", "java"
  },
  highlight = { enable = true },
  indent    = { enable = true },
}

-- ========== LSP CONFIGURATION ==========
require("mason").setup()
require("mason-lspconfig").setup({ automatic_installation = true })

local lspconfig = require("lspconfig")

local servers = { "pyright", "ts_ls", "html", "cssls", "clangd", "lua_ls" }  -- rust handled by rust-tools

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
  }
end

-- ========== AUTOCOMPLETION ==========
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args) require("luasnip").lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<Tab>']     = cmp.mapping.select_next_item(),
    ['<S-Tab>']   = cmp.mapping.select_prev_item(),
    ['<CR>']      = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }),
})

-- ========== TELESCOPE (File Search) ==========
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find Files" })
vim.keymap.set('n', '<leader>fg', builtin.live_grep,  { desc = "Live Grep" })

-- ========== NVIM-TREE (File Explorer) ==========
require("nvim-tree").setup()
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = "Toggle File Explorer" })

-- ========== LUALINE (Statusline) ==========
require('lualine').setup { options = { theme = 'tokyonight' } }

-- ========== GITSIGNS ==========
require('gitsigns').setup()
vim.keymap.set('n', '<leader>gs', ':Gitsigns preview_hunk<CR>', { desc = "Preview Git Hunk" })

-- ========== AUTOPAIRS ==========
require("nvim-autopairs").setup()

-- ========== WHICH-KEY ==========
require("which-key").setup()

-- ========== INDENT-BLANKLINE ==========
require("ibl").setup()

-- ========== COMMENT.NVIM ==========
require('Comment').setup()

-- ========== OTHER NICE KEYMAPS ==========
vim.keymap.set('n', '<leader>w', ':w<cr>', { desc = "Save" })
vim.keymap.set('n', '<leader>q', ':q<cr>', { desc = "Quit" })
vim.keymap.set('n', '<leader>h', ':nohlsearch<cr>', { desc = "No Highlight" })

-- ========== JAVA LSP - nvim-jdtls auto-start ==========
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    local jdtls = require('jdtls')

    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
    local workspace_dir = vim.fn.stdpath('data') .. '/jdtls-workspace/' .. project_name

    local jdtls_path = vim.fn.stdpath('data') .. '/mason/packages/jdtls'
    local config_dir = jdtls_path .. '/config_win'  -- change to config_mac or config_linux for your OS
    local jar_pattern = jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar'
    local launcher_jar = vim.fn.glob(jar_pattern)

    local config = {
      cmd = {
        'java',
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        '-Xms1g',
        '--add-modules=ALL-SYSTEM',
        '--add-opens', 'java.base/java.util=ALL-UNNAMED',
        '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
        '-jar', launcher_jar,
        '-configuration', config_dir,
        '-data', workspace_dir,
      },
      root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew', 'pom.xml'}),
    }

    jdtls.start_or_attach(config)
  end,
})

-- ========== END OF CONFIG ==========
-- After first launch, run :Mason to install recommended language servers and :TSInstall rust java to install Treesitter parsers
