---@class ctest-config-provider.MappedConfig: ctest-config-provider.Config
--- @field templates ctest-config-provider.Mapping[]
--- @field ft_filter {[string]: boolean}?

--- @type ctest-config-provider.Config
local default_config = {
	ctest_command = "ctest",
	test_dirs = { "build", "build/debug" },
	timeout_ms = 5000,
	templates = {},
	ft_filter = { "c", "cpp" },
	test_filter = "line",
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

	if #mapped_opts.ft_filter > 0 then
		local ft_filter = {}
		for _, v in ipairs(mapped_opts.ft_filter) do
			ft_filter[v] = true
		end
		mapped_opts.ft_filter = ft_filter
	else
		mapped_opts.ft_filter = nil
	end

	---@cast mapped_opts ctest-config-provider.MappedConfig
	return mapped_opts
end
