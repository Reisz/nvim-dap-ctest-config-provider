local M = {}

--- @class ctest-config-provider.TestInfo
--- @field name string Name of the test
--- @field program string Test executable
--- @field args string Arguments for the test executable
--- @field cwd? string Working directory for the test

--- @alias ctest-config-provider.Mapping fun(ctest-config-provider.TestInfo): dap.Configuration Mapping from test info to debugee configuration

--- @class ctest-config-provider.Config
--- @field ctest_command string ctest program location
--- @field test_dirs string[] ctest test directory search list relative to NVIM CWD. Results from every existing folder are combined to form the final list.
--- @field timeout_ms number Timeout of ctest invocation in milliseconds
--- @field templates (string | ctest-config-provider.Mapping)[] List of debugee configuration mappings. Use a string to get a simple mapping to that debugger type.
--- @field ft_filter string[] Skip, if the current buffer is not one of the listed filetypes. Leave empty to never skip.
--- @field test_filter "none"|"file"|"line"

--- @param opts ctest-config-provider.Config
M.setup = function(opts)
	local mapped_opts = require("ctest-config-provider.map_plugin_config")(opts)
	require("dap").providers.configs["ctest-config-provider"] = function()
		return require("ctest-config-provider.get_debugeee_configs")(mapped_opts)
	end
end

return M
