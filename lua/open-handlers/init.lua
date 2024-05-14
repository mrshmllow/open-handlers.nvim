local M = {
	handlers = {},
}

M.native = vim.ui.open

---@param url string
---@return string
local function ssh_to_http(url)
	local provider, path = url:match("git@(.-):(.+)")
	if provider and path then
		-- found a few Gitlab instances with ssh. subdomain
		provider = provider:gsub("^ssh%.", "")
		return ("https://%s/%s"):format(provider, path)
	end

	return url
end

---remove `.git` from the end of the url
---@param url string
---@return string
local function clean_git(url)
	local clean = string.gsub(url, "%.git%s*$", "")
	return clean
end

---@return nil|string
local function get_git_origin()
	local res = vim.system({ "git", "config", "--get", "remote.upstream.url" }, { text = true }):wait()

	if res.code ~= 0 then
		res = vim.system({ "git", "config", "--get", "remote.origin.url" }, { text = true }):wait()
		if res.code ~= 0 then
			return nil
		end
	end

	return ssh_to_http(res.stdout)
end

local FAILED_GET_ORIGIN = "Failed to get git remote.origin.url"

function M.issue(path)
	if vim.startswith(path, "#") then
		path = path:sub(2)

		local res = get_git_origin()

		if res == nil then
			return nil, FAILED_GET_ORIGIN
		end

		res = clean_git(res)

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

		if res ~= nil then
			return nil, nil
		end
	end

	return nil, "open-handler: no handler was successful"
end

return M
