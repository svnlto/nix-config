-- LSP Configuration
return {
	-- Configure nvim-lspconfig
	{
		"neovim/nvim-lspconfig",
		opts = {
			inlay_hints = { enabled = false }, -- Disable inlay hints by default (toggle with <leader>uh)
			-- Configure LSP servers
			servers = {
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

				-- YAML Language Server with Kubernetes support
				yamlls = {
					-- Explicitly set filetypes to exclude helm and jinja templates
					filetypes = { "yaml", "yaml.ansible" },
					settings = {
						yaml = {
							keyOrdering = false,
							validate = true,
							schemas = {
								-- Kubernetes - match common filename patterns
								kubernetes = {
									"deployment.yaml",
									"service.yaml",
									"configmap.yaml",
									"secret.yaml",
									"ingress.yaml",
									"*-deployment.yaml",
									"*-service.yaml",
									"*-configmap.yaml",
									"*-secret.yaml",
									"*-ingress.yaml",
									"**/*-deployment.yaml",
									"**/*-service.yaml",
								},
								-- GitHub Actions
								["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.{yaml,yml}",
								-- External Secrets
								["https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/external-secrets.io/externalsecret_v1beta1.json"] = "*externalsecret.yaml",
							},
						},
					},
				},

				-- Helm Language Server
				helm_ls = {},
			},
		},
	},

	-- Mason configuration
	{
		"mason-org/mason.nvim",
		opts = {
			ensure_installed = {
				"typescript-language-server",
				"gopls",
				"terraform-ls",
				"lua-language-server",
				"biome",
				"yaml-language-server",
				"helm-ls",
			},
		},
	},

	-- Mason LSP Config
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {
				"ts_ls",
				"gopls",
				"terraformls",
				"lua_ls",
				"biome",
				"yamlls",
				"helm_ls",
			},
		},
	},
}
