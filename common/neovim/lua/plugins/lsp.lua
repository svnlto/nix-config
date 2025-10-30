-- LSP Configuration
return {
	-- Configure nvim-lspconfig
	{
		"neovim/nvim-lspconfig",
		opts = {
			inlay_hints = { enabled = false }, -- Disable inlay hints by default (toggle with <leader>uh)
			-- Configure LSP servers
			servers = {
				-- YAML Language Server - exclude helm values files (handled by helm_ls)
				yamlls = {
					filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
				},
				-- Helm Language Server - disable yamlls diagnostics for Jinja2 templates
				helm_ls = {
					settings = {
						["helm-ls"] = {
							yamlls = {
								diagnosticsLimit = 0, -- Disable yamlls diagnostics (keeps hover/completion)
							},
						},
					},
				},
				-- TypeScript/JavaScript (updated name)
				ts_ls = {
					settings = {
						typescript = {
							inlayHints = {
								includeInlayParameterNameHints = "literal",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = false,
								includeInlayVariableTypeHints = false,
								includeInlayPropertyDeclarationTypeHints = false,
								includeInlayFunctionLikeReturnTypeHints = false,
								includeInlayEnumMemberValueHints = false,
							},
						},
						javascript = {
							inlayHints = {
								includeInlayParameterNameHints = "all",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
						},
					},
				},

				-- Go
				gopls = {
					settings = {
						gopls = {
							gofumpt = true,
							codelenses = {
								gc_details = false,
								generate = true,
								regenerate_cgo = true,
								run_govulncheck = true,
								test = true,
								tidy = true,
								upgrade_dependency = true,
								vendor = true,
							},
							hints = {
								assignVariableTypes = true,
								compositeLiteralFields = true,
								compositeLiteralTypes = true,
								constantValues = true,
								functionTypeParameters = true,
								parameterNames = true,
								rangeVariableTypes = true,
							},
							analyses = {
								fieldalignment = true,
								nilness = true,
								unusedparams = true,
								unusedwrite = true,
								useany = true,
							},
							usePlaceholders = true,
							completeUnimported = true,
							staticcheck = true,
							directoryFilters = { "-.git", "-node_modules" },
							semanticTokens = true,
						},
					},
				},

				-- Terraform
				terraformls = {
					filetypes = { "terraform", "tf" },
				},

				-- Lua (for Neovim config)
				lua_ls = {
					settings = {
						Lua = {
							runtime = { version = "LuaJIT" },
							diagnostics = { globals = { "vim" } },
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
								checkThirdParty = false,
							},
							telemetry = { enable = false },
						},
					},
				},

				-- Biome LSP (official integration)
				biome = {
					filetypes = { "javascript", "javascriptreact", "json", "jsonc", "typescript", "typescriptreact" },
					root_dir = function(fname)
						local lspconfig = require("lspconfig")
						return lspconfig.util.root_pattern("biome.json", ".git")(fname)
					end,
				},
			},
		},
	},

	-- Mason configuration (LazyVim helm/yaml extras handle yamlls and helm_ls)
	{
		"mason-org/mason.nvim",
		opts = {
			ensure_installed = {
				"typescript-language-server",
				"gopls",
				"terraform-ls",
				"lua-language-server",
				"biome",
			},
		},
	},

	-- Mason LSP Config (LazyVim helm/yaml extras handle yamlls and helm_ls)
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {
				"ts_ls",
				"gopls",
				"terraformls",
				"lua_ls",
				"biome",
			},
		},
	},
}
