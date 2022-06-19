local M = {}

local default_config = {
	integration = {
		bufferline = true,
		nvim_dap = true
	},
	links = {
		["local"] = "~/code/local",
		["https://codeforces.com/contest/(%d+)/problem/(%w+)"] = "~/code/contest/codeforces",
		["https://codeforces.com/problemset/problem/(%d+)/(%w+)"] = "~/code/contest/codeforces",
	},
	layouts = {
		floating = {},
		default = {
			cmd = "set nosplitright | vs | setl wfw | wincmd w | bel sp | vs | vs | 1wincmd w",
			order = { 1, 2, 3, 4, 5 }, -- main, errors, input, output, expected output
		},
	},
	default_layout = "default",
	langs = {
		cpp = {
			main = { "sol.cpp", "g++ -Wall -O2 -o sol", "./sol" },
			brute = { "brute.cpp", "g++ -Wall -O2 -o brute", "./brute" },
			gen = { "gen.cpp", "g++ -Wall -O2 -o gen", "./gen" },
		},
	},
	default_lang = "cpp",
}

function M.highlight()
	-- Create Cp highlight groups
	local highlight_groups = {
		CpHD = { fg = "#ffffff", bg = "#000000" },
		CpfHD = { fg = "#000000", bg = "#ffffff" },
		CpNA = { fg = "#ffffff", bg = "#ABB2BF" },
		CpfNA = { fg = "#000000", bg = "#ABB2BF" },
		CpPD = { fg = "#C678DD", bg = "#ffffff" },
		CpfPD = { fg = "#000000", bg = "#ABB2BF" },
		CpAC = { fg = "#ffffff", bg = "#98C379" },
		CpfAC = { fg = "#000000", bg = "#98C379" },
		CpWA = { fg = "#ffffff", bg = "#E06C75" },
		CpfWA = { fg = "#000000", bg = "#E06C75" },
		CpRE = { fg = "#ffffff", bg = "#61AFEF" },
		CpfRE = { fg = "#000000", bg = "#61AFEF" },
		CpTL = { fg = "#ffffff", bg = "#E5C07B" },
		CpfTL = { fg = "#000000", bg = "#E5C07B" },
		CpFL = { fg = "#000000", bg = "NONE" },
	}
	for name, val in pairs(highlight_groups) do
		vim.api.nvim_set_hl(0, name, val)
	end
end

function M.setup(user_config)
	CpConfig = vim.tbl_deep_extend("force", user_config, default_config)
	CpProblemClass = {}
	CpProblemList = {}
	CpProblem = {}
	require("cp.problem")
	require("cp.test")
	require("cp.layout")

	local load_command = function(cmd, ...)
		local args = { ... }
		require("cp.command")[cmd].run(args)
	end
	vim.api.nvim_create_user_command("Cp", function(info)
		load_command(unpack(info.fargs))
	end, {
		nargs = "*",
		complete = function(_, line)
			local commands = require "cp.command"
			local builtin_list = vim.tbl_keys(commands)

			local l = vim.split(line, "%s+")
			local n = #l - 2

			if n == 0 then
				return vim.tbl_filter(function(val)
					return vim.startswith(val, l[2])
				end, builtin_list)
			end

			if n == 1 then
				local extension = commands[l[2]]
				if extension then
					return vim.tbl_filter(function(val)
						return vim.startswith(val, l[3])
					end, extension.complete())
				end
			end
		end,
	})

	-- create highlight groups
	M.highlight()

	vim.api.nvim_create_autocmd("ColorScheme", {
		pattern = "*",
		callback = function()
			require("cp").highlight()
		end,
	})

	vim.api.nvim_create_autocmd("TabEnter", {
		pattern = "*",
		callback = function()
			CpProblem:problem(vim.api.nvim_get_current_tabpage())
		end,
	})

	-- Tabline custom support, deprecated by neovim 0.8
	vim.cmd [[
		function CpTab(num, clicks, button, flags)
			execute "lua require'cp.layout'.tab(" . a:num . ")"
		endfunction
		function CpTest(num, clicks, button, flags)
			if a:button == 'r'
				execute "lua require'cp.test'.hide_show(" . a:num . ")"
			else
				execute "lua require'cp.test'.switch(" . a:num . ")"
			endif
		endfunction]]
end

return M
