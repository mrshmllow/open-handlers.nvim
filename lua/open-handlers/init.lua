local M = {
	handlers = {},
}

M.native = vim.ui.open

---@return nil|string
local function get_git_origin()
	local res = vim.system({ "git", "config", "--get", "remote.origin.url" }, { text = true }):wait()

	if res.code ~= 0 then
		return nil
	end

	return res.stdout
end

local FAILED_GET_ORIGIN = "Failed to get git remote.origin.url"

function M.issue(path)
	if vim.startswith(path, "#") then
		path = path:sub(2)

		local res = get_git_origin()

		if res == nil then
			return nil, FAILED_GET_ORIGIN
		end

		return M.native(res .. "/issues/" .. path)
	end

	return nil, nil
end

function M.commit(path)
	local res = vim.system({ "git", "rev-parse", "--verify", "--quiet", path }, { text = true }):wait()

	if res.code ~= 0 then
		return nil, nil
	end

	local origin = get_git_origin()

	if origin == nil then
		return nil, FAILED_GET_ORIGIN
	end

	return M.native(origin .. "/commit/" .. res.stdout)
end

function M.setup(opts)
	opts = opts or {}

	M.handlers = opts.handlers and opts.handlers or {
		M.native,
	}
end

function vim.ui.open(path)
	vim.validate({
		path = { path, "string" },
	})

	for _, handler in ipairs(M.handlers) do
		local res, err = handler(path)

		if err ~= nil then
			return res, err
		end

		if res == nil then
			return nil, nil
		end
	end

	return nil, "open-handler: no handler was successful"
end

return M
