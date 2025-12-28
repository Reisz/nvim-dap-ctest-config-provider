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

--- @param opts ctest-config-provider.MappedConfig
--- @return dap.Configuration[]
return function(opts)
	if opts.ft_filter and not opts.ft_filter[vim.bo.filetype] then
		return {}
	end

	local result = {}

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
				local test_info = {}
				test_info.name = test.name

				test_info.program = test.command[1]
				table.remove(test.command, 1)
				test_info.args = test.command

				for _, property in ipairs(test.properties) do
					if property.name == "WORKING_DIRECTORY" then
						test_info.cwd = property.value
					end
				end

				for _, v in ipairs(opts.templates) do
					table.insert(result, v(vim.deepcopy(test_info)))
				end
			end
		end
	end

	return result
end
