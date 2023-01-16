local api = vim.api

local M = {}

local function get_current_cursor_word()
	return api.nvim_call_function("expand", { "<cword>" })
end

local function exec_sdcv_command(word)
	if not vim.fn.executable("sdcv") then
		vim.notify("please install sdcv command.", vim.log.levels.ERROR)
		return nil
	end

	local cmd = { "sdcv" .. " -n " .. word }
	local output = api.nvim_call_function("system", cmd)
	local lines = {}
	for line in string.gmatch(output, "([^\n]+)") do
		table.insert(lines, line)
	end
	return lines
end

function M:show(word)
	local current_buf = api.nvim_get_current_buf()

	local lines = exec_sdcv_command(word)
	if not lines then
		return
	end

	local _, win_height = vim.lsp.util._make_floating_popup_size(lines, {})

	local bufnr = api.nvim_create_buf(false, true)
	api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
	local max_float_window_width = math.floor(vim.o.columns * 0.6)
	local opts = {
		relative = "cursor",
		width = max_float_window_width,
		height = win_height,
		row = 1,
		col = 0,
		style = "minimal",
		border = "single",
	}
	local winid = api.nvim_open_win(bufnr, true, opts)

	vim.keymap.set("n", "q", function()
		if winid and api.nvim_win_is_valid(winid) then
			api.nvim_win_close(winid, true)
		end
	end, { buffer = bufnr })

	-- TODO: <C-f><C-b>によるfloating windowのスクロール実装
	--vim.keymap.set("n", "<C-f>", function()
	-- execute to scroll
	--end, { buffer = current_buf })

	api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
		buffer = current_buf,
		once = true,
		callback = function()
			if bufnr and api.nvim_buf_is_loaded(bufnr) then
				api.nvim_buf_delete(bufnr, { force = true })
			end

			if winid and api.nvim_win_is_valid(winid) then
				api.nvim_win_close(winid, true)
			end
		end,
		desc = "[Strdict] Auto close hover window",
	})
end

function M:show_cursor()
	local word = get_current_cursor_word()
	M:show(word)
end

return M
