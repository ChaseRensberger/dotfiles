vim.g.mapleader = " "
vim.keymap.set("n", "<leader>e", vim.cmd.Ex)
vim.keymap.set("n", "<leader>b", "<C-^>", { desc = "Jump to previous buffer" })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic message" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"

-- vim.api.nvim_create_autocmd("FileType", {
-- 	pattern = "netrw",
-- 	callback = function()
-- 		vim.api.nvim_buf_set_keymap(0, "n", "a", "%:call netrw#NetrwBrowseX('%')", { noremap = true, silent = true })
-- 	end,
-- })

-- vim.g.maplocalleader = "\\"

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out,                            "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		{
			"rose-pine/neovim",
			name = "rose-pine",
			lazy = false,
		},
		{
			"neanias/everforest-nvim",
			name = "everforest",
			lazy = false,
		},
		{
			"nvim-telescope/telescope.nvim",
			tag = "0.1.8",
			dependencies = { "nvim-lua/plenary.nvim" },
		},
		{
			"nvim-treesitter/nvim-treesitter",
			build = ":TSUpdate",
		},
		{
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"neovim/nvim-lspconfig",
		},
		{
			"stevearc/conform.nvim",
			opts = {},
		},
		{ "hrsh7th/cmp-nvim-lsp" },
		{ "hrsh7th/cmp-buffer" },
		{ "hrsh7th/cmp-path" },
		{ "hrsh7th/cmp-cmdline" },
		{ "hrsh7th/nvim-cmp" },
		{ "L3MON4D3/LuaSnip" },
		{ "rafamadriz/friendly-snippets" },
		{ "numToStr/Comment.nvim" },
		{ "m4xshen/autoclose.nvim" },
	},
	-- automatically check for plugin updates
	checker = { enabled = false },
})

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })

-- vim.cmd("colorscheme rose-pine")
vim.cmd("colorscheme everforest")

vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
---@diagnostic disable-next-line: missing-fields
require("nvim-treesitter.configs").setup({
	-- A list of parser names, or "all" (the listed parsers MUST always be installed)
	ensure_installed = {
		"lua",
		"markdown",
		"markdown_inline",
		"javascript",
		"typescript",
		"go",
		"html",
		"css",
		"rust",
		"yaml",
		"scala",
		"python",
		"terraform",
		"cpp"
	},

	-- Install parsers synchronously (only applied to `ensure_installed`)
	sync_install = false,

	-- Automatically install missing parsers when entering buffer
	-- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
	auto_install = true,

	highlight = {
		enable = true,
		-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
		-- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
		-- Using this option may slow down your editor, and you may see some duplicate highlights.
		-- Instead of true it can also be a list of languages
		additional_vim_regex_highlighting = false,
	},
})

local cmp = require("cmp")

cmp.setup({
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
	}, {
		{ name = "buffer" },
	}),
})

require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = { "lua_ls", "ts_ls", "gopls", "html", "cssls", "rust_analyzer", "clangd" },
	automatic_installation = true,
	automatic_enable = true,
})
-- I also like to have basedpyright installed but I do it manually with uv

local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("lspconfig")["lua_ls"].setup({
	capabilities = capabilities,
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
		},
	},
})

local servers_with_defaults = { "rust_analyzer", "ts_ls", "gopls", "html", "cssls", "basedpyright", "clangd" }

for _, server in ipairs(servers_with_defaults) do
	require("lspconfig")[server].setup({
		capabilities = capabilities,
	})
end

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		html = { "prettier" },
		css = { "prettier" },
		yaml = { "prettier" },
		go = { "gofumpt" },
		rust = { "rust-analyzer" },
		python = { "isort", "black" },
		cpp = { "clang-format" }
	},
	formatters = {
		black = {
			prepend_args = { "--fast", "--target-version", "py312" },
		},
	},
	format_on_save = {
		timeout_ms = 5000,
		lsp_format = "fallback",
	},
})

require("Comment").setup()
vim.keymap.set("n", "<leader>/", function()
	require("Comment.api").toggle.linewise.current()
end, { desc = "Toggle comment on current line" })
vim.keymap.set(
	"v",
	"<leader>/",
	"<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
	{ desc = "Toggle comment on selected lines" }
)

require("autoclose").setup()

vim.api.nvim_create_user_command("Reload", function()
	local cursor_position = vim.api.nvim_win_get_cursor(0)
	vim.cmd("edit!")
	vim.api.nvim_win_set_cursor(0, cursor_position)
end, {})

local function disable_lsp()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients > 0 then
		for _, client in ipairs(clients) do
			vim.lsp.stop_client(client.id)
		end
		print("LSP disabled for current buffer")
	end
end

vim.api.nvim_create_user_command("DisableLSP", disable_lsp, {})

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("typst", {
	s("act", {
		t("#action["),
		t({ "", "  " }),
		i(0, "action"),
		t({ "", "]" }),
	}),
	s("dia", {
		t("#dialogue_block["),
		t({ "", "  " }),
		i(0),
		t({ "", "]" }),
	}),
	s("sce", {
		t("#scene(\""),
		i(0, "scene"),
		t({ "\")" }),
	}),
	s("lin", {
		t("#line["),
		i(0, "line"),
		t({ "]" }),
	}),
	s("cha", {
		t("#character(\""),
		i(0, "character"),
		t({ "\")" }),
	}),
	s("par", {
		t("#parenthetical(\""),
		i(0, "parenthetical"),
		t({ "\")" }),
	}),
	s("start", {
		t("#import \"template.typ\": *"),
		t({ "", "" }),
		t({ "", "" }),
		t("#show: screenplay.with("),
		t({ "", "  title: \"" }),
		i(0, "title"),
		t("\""),
		t({ "", ")" }),
	}),
})

vim.keymap.set("i", "<C-k>", function()
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end, { silent = true })
