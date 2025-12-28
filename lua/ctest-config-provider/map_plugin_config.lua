---@class ctest-config-provider.MappedConfig
--- @field ctest_command string
--- @field test_dirs string[]
--- @field timeout_ms number
--- @field templates ctest-config-provider.Mapping[]

--- @type ctest-config-provider.Config
local default_config = {
	ctest_command = "ctest",
	test_dirs = { "build", "build/debug" },
	timeout_ms = 5000,
	templates = {},
}

--- @param type string Adapter name
--- @return ctest-config-provider.Mapping
local function create_simple_template(type)
	return function(test_info)
		test_info.name = "Launch with " .. type .. ": " .. test_info.name
		test_info.type = type
		test_info.request = "launch"
		return test_info
	end
end

---@param opts ctest-config-provider.Config
---@return ctest-config-provider.MappedConfig
return function(opts)
	local mapped_opts = vim.tbl_deep_extend("force", default_config, opts or {})

	for i, v in ipairs(opts.templates) do
		if type(v) == "string" then
			mapped_opts.templates[i] = create_simple_template(v)
		end
	end

	---@cast mapped_opts ctest-config-provider.MappedConfig
	return mapped_opts
end
