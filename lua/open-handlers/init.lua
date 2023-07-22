local M = {
	handlers = {},
}

M.native = vim.ui.open

function M.issue(path)
	if vim.startswith(path, "#") then
		vim.print("using github")

		path = path:sub(2)

		local res = vim.system({ "git", "config", "--get", "remote.origin.url" }, { text = true }):wait()

		if res.code ~= 0 then
			return nil, "Failed to get git remote.origin.url"
		end

		-- Works on github and gitlab!
		return M.native(res.stdout .. "/issues/" .. path)
	end

	return nil, nil
end

function M.setup(opts)
	opts = opts or {}

	M.handlers = opts.handlers and opts.handlers or {}
end

function vim.ui.open(path)
	vim.validate({
		path = { path, "string" },
	})

	for _, handler in ipairs(M.handlers) do
		local res, err = handler(path)

		if res ~= nil then
			return res, err
		end
	end

	return nil, "open-handler: no handler was successful"
end

return M
