return {
	{
		"maidinhhuy/spring-boot.nvim",
		-- dir = "/home/richardmai/workspace/neovim-plugins/spring-boot-nvim",
		-- name = "spring-boot.nvim",
		version = "*",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim", "akinsho/toggleterm.nvim" },
		config = function()
			local sb = require("spring-boot.nvim")
			sb.setup()
			--
			-- vim.api.nvim_create_user_command("SpringBootRun", sb.find_mvnw, {})
			-- vim.api.nvim_create_user_command("SpringBootInit", sb.create_project, {})
			-- vim.api.nvim_create_user_command("SpringBootSelectAndRunGoal", sb.select_and_run_goal, {})
			--
			-- vim.keymap.set("n", "<leader>sr", sb.find_mvnw, { desc = "Run Spring Boot (find mvnw)" })
			-- vim.keymap.set("n", "<leader>ss", sb.select_and_run_goal, { desc = "Spring Boot Actions" })
		end,
		init = function()
			require("spring-boot.nvim")
		end,
	},
}
