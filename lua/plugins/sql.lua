return {
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
		},
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
		keys = {
			{ "<C-r>", ":DB<CR>", mode = "v", desc = "Run selected SQL (dadbod)" },
			{ "<C-r>", "ggVG:DB<CR>", mode = "n", desc = "Run entire SQL buffer (dadbod)" },
		},
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
		end,
	},
	{
		"kristijanhusak/vim-dadbod-completion",
		ft = { "sql", "mysql", "plsql" },
		dependencies = { "hrsh7th/nvim-cmp" },
		config = function()
			require("cmp").setup.filetype({ "sql" }, {
				sources = {
					{ name = "vim-dadbod-completion" },
					{ name = "buffer" },
				},
			})
		end,
	},
	 { -- optional saghen/blink.cmp completion source
		'saghen/blink.cmp',
		opts = {
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
			per_filetype = {
			sql = { 'snippets', 'dadbod', 'buffer' },
			},
			-- add vim-dadbod-completion to your completion providers
			providers = {
			dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
			},
		},
		},
  	}
}
