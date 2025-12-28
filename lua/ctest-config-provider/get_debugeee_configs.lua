local bit = require("bit")

local S_IFMT = 0xF000
local S_IFDIR = 0x4000

--- @param cmd string[]
--- @param opts vim.SystemOpts
--- @return vim.SystemCompleted
local function async_system(cmd, opts)
	local co = coroutine.running()
	local result = nil
	vim.system(
		cmd,
		opts,
		vim.schedule_wrap(function(result_in)
			result = result_in
			if coroutine.status(co) == "suspended" then
				coroutine.resume(co)
			end
		end)
	)
	if not result then
		coroutine.yield()
	end

	--- @cast result vim.SystemCompleted
	return result
end

---@class ctest-config-provider.Test
---@field info ctest-config-provider.TestInfo
---@field file string
---@field line integer

---@return ctest-config-provider.Test
local function map_test(ctest_test)
	local test = { info = {} }
	test.info.name = ctest_test.name

	test.info.program = ctest_test.command[1]
	table.remove(ctest_test.command, 1)
	test.info.args = ctest_test.command

	for _, property in ipairs(ctest_test.properties) do
		if property.name == "WORKING_DIRECTORY" then
			test.info.cwd = property.value
		end

		if property.name == "DEF_SOURCE_LINE" then
			local file, line = string.match(property.value, "([^:]*):([^:]*)")
			test.file = file
			test.line = tonumber(line)
		end
	end

	return test
end

--- @param opts ctest-config-provider.MappedConfig
--- @return dap.Configuration[]
return function(opts)
	if opts.ft_filter and not opts.ft_filter[vim.bo.filetype] then
		return {}
	end

	---@type ctest-config-provider.Test[]
	local tests = {}
	for _, test_dir in ipairs(opts.test_dirs) do
		local stat = vim.uv.fs_stat(test_dir)
		if stat and bit.band(stat.mode, S_IFMT) == S_IFDIR then
			local process_result = async_system({ opts.ctest_command, "--show-only=json-v1" }, {
				cwd = test_dir,
				timeout = opts.timeout_ms,
			})
			assert(process_result.code == 0, "ctest process failed")

			local ctest_info = vim.json.decode(process_result.stdout)
			assert(ctest_info.kind == "ctestInfo", "Unexpected data kind")
			assert(ctest_info.version.major == 1 and ctest_info.version.minor == 0, "Unexpected version")

			for _, test in ipairs(ctest_info.tests) do
				table.insert(tests, map_test(test))
			end
		end
	end

	---@type ctest-config-provider.Config[]
	local result = {}

	---@param test ctest-config-provider.Test
	local function insert_mapped(test)
		for _, map in ipairs(opts.templates) do
			table.insert(result, map(vim.deepcopy(test.info)))
		end
	end

	local file = vim.api.nvim_buf_get_name(0)
	local line = vim.fn.line(".")
	if opts.test_filter == "line" then
		table.sort(tests, function(lhs, rhs)
			return lhs.line < rhs.line
		end)
		local prev = nil
		for _, v in ipairs(tests) do
			if v.file == file and v.line > line and prev then
				insert_mapped(prev)
				return result
			end
			prev = v
		end
	elseif opts.test_filter == "file" then
		for _, v in ipairs(tests) do
			if v.file == file then
				insert_mapped(v)
			end
		end
	elseif opts.test_filter == "none" then
		for _, v in ipairs(tests) do
			insert_mapped(v)
		end
	else
		assert(false, "Unknown test_filter value: " .. opts.test_filter)
	end

	return result
end
