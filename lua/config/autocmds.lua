-- set tab to 3 space when entering a buffet with .lua file
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = { "*.lua" },
	callback = function()
		vim.opt.shiftwidth = 3
		vim.opt.tabstop = 3
		vim.opt.softtabstop = 3
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = { "*.java" },
	callback = function()
		vim.opt.shiftwidth = 2
		vim.opt.tabstop = 2
		vim.opt.softtabstop = 2
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = { "*.py" },
	callback = function()
		vim.opt.shiftwidth = 4
		vim.opt.tabstop = 4
		vim.opt.softtabstop = 4
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = { "*.js", "*.ts", "*.tsx", "*.jsx" },
	callback = function()
		vim.opt.shiftwidth = 2
		vim.opt.tabstop = 2
		vim.opt.softtabstop = 2
	end,
})
