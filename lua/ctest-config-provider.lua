local M = {}

--- @class ctest-config-provider.TestInfo
--- @field name string Name of the test
--- @field program string Test executable
--- @field args string Arguments for the test executable
--- @field cwd string Working directory for the test

--- @alias ctest-config-provider.Mapping fun(ctest-config-provider.TestInfo): dap.Configuration Mapping from test info to debugee configuration

--- @class ctest-config-provider.Config
--- @field ctest_command string ctest program location
--- @field test_dir string ctest test directory relative to NVIM CWD
--- @field timeout_ms number Timeout of ctest invocation in milliseconds
--- @field templates (string | ctest-config-provider.Mapping)[] List of debugee configuration mappings. Use a string to get a simple mapping to that debugger type.

--- @type ctest-config-provider.Config
local default_config = {
	ctest_command = "ctest",
	test_dir = "build",
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

--- @param opts ctest-config-provider.Config
M.setup = function(opts)
	opts = vim.tbl_deep_extend("force", default_config, opts or {})

	for i, v in ipairs(opts.templates) do
		if type(v) == "string" then
			opts.templates[i] = create_simple_template(v)
		end
	end

	require("dap").providers.configs["ctest-config-provider"] = function()
		return require("ctest-config-provider.get_configs")(opts)
	end
end

return M
