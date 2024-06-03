-- Utility function to extend or override a config table, similar to the way
-- that Plugin.opts works
---@param config table
---@param custom function | table | nil
local function extend_or_override(config, custom, ...)
	if type(custom) == "function" then
		config = custom(config, ...) or config
	elseif custom then
		config = vim.tbl_deep_extend("force", config, custom) --[[@as table]]
	end
	return config
end

local java_filetypes = { "java" }

return {
	"mfussenegger/nvim-jdtls",
	dependencies = { "folke/which-key.nvim" },
	ft = java_filetypes,
	opts = function()
		return {
			-- How to find the root dir for a given filename. The default comes from
			-- lspconfig which provides a function specifically for java projects.
			root_dir = require("lspconfig.server_configurations.jdtls").default_config.root_dir,

			-- How to find the project name for a given root dir.
			project_name = function(root_dir)
				return root_dir and vim.fs.basename(root_dir)
			end,

			-- Where are the config and workspace dirs for a project?
			jdtls_config_dir = function(project_name)
				return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/config"
			end,
			jdtls_workspace_dir = function(project_name)
				return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"
			end,

			-- How to run jdtls. This can be overridden to a full java command-line
			-- if the Python wrapper script doesn't suffice.
			cmd = { vim.fn.exepath("jdtls") },
			full_cmd = function(opts)
				local fname = vim.api.nvim_buf_get_name(0)
				local root_dir = opts.root_dir(fname)
				local project_name = opts.project_name(root_dir)
				local cmd = vim.deepcopy(opts.cmd)
				if project_name then
					vim.list_extend(cmd, {
						"-configuration",
						opts.jdtls_config_dir(project_name),
						"-data",
						opts.jdtls_workspace_dir(project_name),
					})
				end
				return cmd
			end,

			-- These depend on nvim-dap, but can additionally be disabled by setting false here.
			dap = { hotcodereplace = "auto", config_overrides = {} },
			dap_main = {},
			test = true,
		}
	end,
	config = function()
		local opts = LazyVim.opts("nvim-jdtls") or {}

		-- Find the extra bundles that should be passed on the jdtls command-line
		-- if nvim-dap is enabled with java debug/test.
		local mason_registry = require("mason-registry")
		local bundles = {
			vim.fn.glob(
				"/home/richardmai/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-0.51.1.jar",
				true
			),
		} ---@type string[]
		vim.list_extend(bundles, vim.split(vim.fn.glob("/home/richardmai/vscode-java-test/server/*.jar", true), "\n"))
		if opts.dap and LazyVim.has("nvim-dap") and mason_registry.is_installed("java-debug-adapter") then
			local java_dbg_pkg = mason_registry.get_package("java-debug-adapter")
			local java_dbg_path = java_dbg_pkg:get_install_path()
			local jar_patterns = {
				java_dbg_path .. "/home/richardmai/vscode-java-test/server/com.microsoft.java.debug.plugin-*.jar",
			}
			-- java-test also depends on java-debug-adapter.
			if opts.test and mason_registry.is_installed("java-test") then
				local java_test_pkg = mason_registry.get_package("java-test")
				local java_test_path = java_test_pkg:get_install_path()
				vim.list_extend(jar_patterns, {
					java_test_path .. "/home/richardmai/vscode-java-test/server/*.jar",
				})
			end
			for _, jar_pattern in ipairs(jar_patterns) do
				for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), "\n")) do
					table.insert(bundles, bundle)
				end
			end
		end

		local function attach_jdtls()
			local fname = vim.api.nvim_buf_get_name(0)

			-- Configuration can be augmented and overridden by opts.jdtls
			local config = extend_or_override({
				cmd = opts.full_cmd(opts),
				root_dir = opts.root_dir(fname),
				init_options = {
					bundles = bundles,
				},
				-- enable CMP capabilities
				capabilities = LazyVim.has("cmp-nvim-lsp") and require("cmp_nvim_lsp").default_capabilities() or nil,
			}, opts.jdtls)

			-- Existing server will be reused if the root_dir matches.
			require("jdtls").start_or_attach(config)
			-- not need to require("jdtls.setup").add_commands(), start automatically adds commands
		end

		-- Attach the jdtls for each java buffer. HOWEVER, this plugin loads
		-- depending on filetype, so this autocmd doesn't run for the first file.
		-- For that, we call directly below.
		vim.api.nvim_create_autocmd("FileType", {
			pattern = java_filetypes,
			callback = attach_jdtls,
		})

		-- Setup keymap and dap after the lsp is fully attached.
		-- https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
		-- https://neovim.io/doc/user/lsp.html#LspAttach
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if client and client.name == "jdtls" then
					local wk = require("which-key")
					wk.register({
						["<leader>cx"] = { name = "+extract" },
						["<leader>cxv"] = { require("jdtls").extract_variable_all, "Extract Variable" },
						["<leader>cxc"] = { require("jdtls").extract_constant, "Extract Constant" },
						["gs"] = { require("jdtls").super_implementation, "Goto Super" },
						["gS"] = { require("jdtls.tests").goto_subjects, "Goto Subjects" },
						["<leader>co"] = { require("jdtls").organize_imports, "Organize Imports" },
					}, { mode = "n", buffer = args.buf })
					wk.register({
						["<leader>c"] = { name = "+code" },
						["<leader>cx"] = { name = "+extract" },
						["<leader>cxm"] = {
							[[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
							"Extract Method",
						},
						["<leader>cxv"] = {
							[[<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>]],
							"Extract Variable",
						},
						["<leader>cxc"] = {
							[[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]],
							"Extract Constant",
						},
					}, { mode = "v", buffer = args.buf })

					if opts.dap and LazyVim.has("nvim-dap") and mason_registry.is_installed("java-debug-adapter") then
						-- custom init for Java debugger
						require("jdtls").setup_dap(opts.dap)
						require("jdtls.dap").setup_dap_main_class_configs(opts.dap_main)

						-- Java Test require Java debugger to work
						if opts.test and mason_registry.is_installed("java-test") then
							-- custom keymaps for Java test runner (not yet compatible with neotest)
							wk.register({
								["<leader>t"] = { name = "+test" },
								["<leader>tt"] = { require("jdtls.dap").test_class, "Run All Test" },
								["<leader>tr"] = { require("jdtls.dap").test_nearest_method, "Run Nearest Test" },
								["<leader>tT"] = { require("jdtls.dap").pick_test, "Run Test" },
							}, { mode = "n", buffer = args.buf })
						end
					end

					function nnoremap(rhs, lhs, desc)
						local bufopts = {}
						bufopts.desc = desc
						vim.keymap.set("n", rhs, lhs, bufopts)
					end

					-- nvim-dap
					nnoremap("<leader>bb", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", "Set breakpoint")
					nnoremap(
						"<leader>bc",
						"<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>",
						"Set conditional breakpoint"
					)
					nnoremap(
						"<leader>bl",
						"<cmd>lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<cr>",
						"Set log point"
					)
					nnoremap("<leader>br", "<cmd>lua require'dap'.clear_breakpoints()<cr>", "Clear breakpoints")
					nnoremap("<leader>ba", "<cmd>Telescope dap list_breakpoints<cr>", "List breakpoints")

					nnoremap("<leader>dc", "<cmd>lua require'dap'.continue()<cr>", "Continue")
					nnoremap("<leader>dj", "<cmd>lua require'dap'.step_over()<cr>", "Step over")
					nnoremap("<leader>dk", "<cmd>lua require'dap'.step_into()<cr>", "Step into")
					nnoremap("<leader>do", "<cmd>lua require'dap'.step_out()<cr>", "Step out")
					nnoremap("<leader>dd", "<cmd>lua require'dap'.disconnect()<cr>", "Disconnect")
					nnoremap("<leader>dt", "<cmd>lua require'dap'.terminate()<cr>", "Terminate")
					nnoremap("<leader>dr", "<cmd>lua require'dap'.repl.toggle()<cr>", "Open REPL")
					nnoremap("<leader>dl", "<cmd>lua require'dap'.run_last()<cr>", "Run last")
					nnoremap("<leader>di", function()
						require("dap.ui.widgets").hover()
					end, "Variables")
					nnoremap("<leader>d?", function()
						local widgets = require("dap.ui.widgets")
						widgets.centered_float(widgets.scopes)
					end, "Scopes")
					nnoremap("<leader>df", "<cmd>Telescope dap frames<cr>", "List frames")
					nnoremap("<leader>dh", "<cmd>Telescope dap commands<cr>", "List commands")

					-- User can set additional keymaps in opts.on_attach
					if opts.on_attach then
						opts.on_attach(args)
					end
				end
			end,
		})

		-- Avoid race condition by calling attach the first time, since the autocmd won't fire.
		-- attach_jdtls()
	end,
}
