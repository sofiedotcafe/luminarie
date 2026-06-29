{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
with lib;

let
  cfg = config.modules.nixos.programs.neovim;
  hasLang = lang: elem lang cfg.languages;
in
{
  options.modules.nixos.programs.neovim = {
    enable = mkEnableOption "Enable Nixvim";

    languages = mkOption {
      type = types.listOf (
        types.enum [
          "c"
          "cpp"
          "rust"
          "nix"
          "yaml"
          "markdown"
          "latex"
          "toml"
          "json"
          "html"
          "css"
          "bash"
          "lua"
          "go"
          "haskell"
        ]
      );
      default = [
        "c"
        "cpp"
        "rust"
        "nix"
        "yaml"
        "markdown"
        "latex"
      ];
      description = "Languages to enable LSP and tooling for.";
    };

    catppuccin.enable = mkEnableOption "Enable Catppuccin theme" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      nixpkgs.source = inputs.nixpkgs;
      globals.mapleader = " ";

      opts = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
        expandtab = true;
        termguicolors = true;
        cursorline = true;
        signcolumn = "yes";
        mouse = "a";
      };

      performance.byteCompileLua = {
        enable = true;
        configs = true;
        initLua = true;
        luaLib = true;
        nvimRuntime = false;
        plugins = true;
      };

      colorschemes.catppuccin.enable = cfg.catppuccin.enable;

      keymaps = [
        {
          mode = "n";
          key = "<leader>e";
          action.__raw = ''
            function()
              require("edgy").toggle("left")
              vim.schedule(function()
                local all_wins = vim.api.nvim_list_wins()
                local edgy = require("edgy")
                for _, win_id in ipairs(all_wins) do
                  local win = edgy.get_win(win_id)
                  if win and win.view.get_title() == "Neo-tree" then
                    vim.api.nvim_set_current_win(win_id)
                    break
                  end
                end
              end)
            end
          '';
          options.desc = "Toggle file explorer with stable focus";
        }
        {
          mode = "n";
          key = "<leader>f";
          action = "<Cmd>Telescope find_files<CR>";
          options.desc = "Find files";
        }
        {
          mode = "n";
          key = "<leader>g";
          action = "<Cmd>Telescope live_grep<CR>";
          options.desc = "Live grep";
        }
        {
          mode = "n";
          key = "<leader>r";
          action = "<Cmd>Telescope oldfiles<CR>";
          options.desc = "Recent files";
        }
        {
          mode = "n";
          key = "<leader>t";
          action = "<Cmd>ToggleTerm direction=float<CR>";
          options.desc = "Floating terminal";
        }
        {
          mode = "n";
          key = "<leader>s";
          action = "<Cmd>Neogit<CR>";
          options.desc = "Git status";
        }
        {
          mode = "n";
          key = "<leader>D";
          action = "<Cmd>DiffviewOpen<CR>";
          options.desc = "Diffview";
        }
      ];

      plugins = {
        lualine.enable = true;
        bufferline.enable = true;
        mini = {
          enable = true;
          modules.tabline = {
            show_icons = true;
            clickable = true;
          };
        };

        colorizer.enable = true;
        web-devicons.enable = true;
        indent-blankline.enable = true;
        illuminate.enable = true;
        scrollview.enable = true;

        neo-tree = {
          enable = true;
          settings.window.mappings = {
            "<cr>" = "open";
          };
        };

        edgy = {
          enable = true;
          settings = {
            animate.enabled = false;
            left = [
              {
                ft = "neo-tree";
                title = "Neo-tree";
              }
              {
                ft = "neogitstatus";
                title = "Neogit";
              }
              {
                ft = "DiffviewFiles";
                title = "Diffview Files";
              }
              {
                ft = "Trouble";
                title = "Trouble";
              }
              {
                ft = "Outline";
                title = "Outline";
              }
            ];
            bottom = [
              {
                ft = "toggleterm";
                title = "Terminal";
              }
              {
                ft = "DiffviewFileHistory";
                title = "Diffview History";
              }
            ];
          };
        };

        telescope = {
          enable = true;
          extensions.fzf-native.enable = true;
        };

        gitsigns.enable = true;
        fugitive.enable = true;
        diffview.enable = true;
        neogit.enable = true;
        codediff.enable = true;

        blink-cmp.enable = true;
        none-ls.enable = true;
        lsp = {
          enable = true;
          inlayHints = true;
          servers = {
            clangd.enable = hasLang "c" || hasLang "cpp";
            nixd.enable = hasLang "nix";
            yamlls.enable = hasLang "yaml";
            marksman.enable = hasLang "markdown";
            texlab.enable = hasLang "latex";
            gopls.enable = hasLang "go";
            hls.enable = hasLang "haskell";
            lua_ls.enable = hasLang "lua";
            bashls.enable = hasLang "bash";
            jsonls.enable = hasLang "json";
            html.enable = hasLang "html";
            cssls.enable = hasLang "css";
            taplo.enable = hasLang "toml";
          };
        };
        rustaceanvim.enable = hasLang "rust";
        lspsaga.enable = true;

        dap.enable = true;
        dap-ui.enable = true;
        dap-virtual-text.enable = true;

        noice = {
          enable = true;
          settings = {
            lsp.override = {
              "vim.lsp.util.convert_input_to_markdown_lines" = true;
              "vim.lsp.util.stylize_markdown" = true;
              "cmp.entry.get_documentation" = true;
            };
            presets = {
              bottom_search = false;
              command_palette = true;
              long_message_to_split = true;
              inc_rename = false;
              lsp_doc_border = true;
            };
            routes = [
              {
                filter = {
                  any = [
                    { event = "msg_show"; }
                    { event = "notify"; }
                  ];
                };
                view = "popup";
              }
            ];
          };
        };
        notify.enable = true;
        dressing.enable = true;

        toggleterm.enable = true;
        direnv = {
          enable = true;
          settings.silent_load = 1;
        };

        treesitter = {
          enable = true;
          settings.ensureInstalled = cfg.languages;
        };
        markview.enable = hasLang "markdown";
        vimtex = {
          enable = hasLang "latex";
          settings = {
            view_method = "zathura";
            compiler_method = "latexmk";
            latexmk = {
              continuous = 1;
              executable = "${lib.getExe' pkgs.texliveFull "latexmk"}";
              options = [
                "-pdf"
                "-interaction=nonstopmode"
                "-synctex=1"
              ];
            };
            callback_enabled = 1;
            view_general_viewer = "${lib.getExe pkgs.zathura}";
            view_general_options = "--synctex-forward @line:@col:@tex";
            conceallevel = 2;
            syntax_conceal = {
              accents = 1;
              ligatures = 1;
              math_delimiters = 1;
            };
            text_flavor = "latex";
            indent_enabled = 1;
            matchparen_enabled = 1;
          };
        };

        image = {
          enable = true;
          settings = {
            backend = "sixel";
            only_render_image_at_cursor = true;
            only_render_image_at_cursor_mode = "popup";
            integrations = {
              markdown.enabled = true;
              neorg.enabled = true;
            };
          };
        };

        alpha = {
          enable = true;
          luaConfig.content = lib.mkForce ''
            local dashboard_image_path = "${./puppygirl.png}"

            local function layout()
              local function button(sc, txt, keybind, keybind_opts, opts)
                local def_opts = {
                  cursor = 3,
                  align_shortcut = "right",
                  hl = "Function",
                  hl_shortcut = "Boolean",
                  width = 35,
                  position = "center",
                }
                opts = opts and vim.tbl_extend("force", def_opts, opts) or def_opts
                opts.shortcut = sc
                local sc_ = sc:gsub("%s", ""):gsub("SPC", "<Leader>")
                local on_press = function()
                  pcall(function() require("image").clear() end)
                  vim.cmd("redraw!")

                  local key = vim.api.nvim_replace_termcodes(keybind or sc_ .. "<Ignore>", true, false, true)
                  vim.api.nvim_feedkeys(key, "t", false)
                end
                if keybind then
                  keybind_opts = vim.F.if_nil(keybind_opts, { noremap = true, silent = true, nowait = true })
                  opts.keymap = { "n", sc_, keybind, keybind_opts }
                end
                return { type = "button", val = txt, on_press = on_press, opts = opts }
              end

              local info_text = function()
                local plugins = #vim.api.nvim_list_runtime_paths()
                local v = vim.version()
                local datetime = os.date(" %d-%m-%Y   %H:%M:%S")
                local platform = vim.fn.has("win32") == 1 and "" or ""
                return string.format(" %d  %s %d.%d.%d  %s", plugins, platform, v.major, v.minor, v.patch, datetime)
              end

              local menu = {
                button("r", "  Recent files", "<Cmd>Telescope oldfiles<CR>"),
                button("e", "  File Explorer", "<Cmd>Neotree toggle<CR>"),
                button("n", "  New file", "<Cmd>ene<CR>"),
                button("f", "  Find file", "<Cmd>Telescope find_files<CR>"),
                button("q", "  Quit", "<Cmd>qa<CR>"),
              }

              return {
                { type = "padding", val = 12 }, 
                { type = "text", val = info_text, opts = { hl = "Special", position = "center" } },
                { type = "padding", val = 2 },
                { type = "group", val = menu, opts = { spacing = 0 } },
                { type = "padding", val = 1 },
                { type = "text", val = require("alpha.fortune")(), opts = { hl = "Comment", position = "center" } },
              }
            end

            require("alpha").setup({
              layout = layout(),
              opts = {
                setup = function()
                  local image = nil
                  local alpha_image_group = vim.api.nvim_create_augroup("AlphaImageRender", { clear = true })
                  local alpha_buf = vim.api.nvim_get_current_buf()
                  local win = vim.api.nvim_get_current_win()
                  local image_width = 16
                  local row = 1

                  local function render_dashboard_image()
                    if vim.api.nvim_get_current_buf() ~= alpha_buf then return end
                    
                    vim.schedule(function()
                      if vim.api.nvim_get_current_buf() ~= alpha_buf or not vim.api.nvim_win_is_valid(win) then return end
                      
                      local win_width = vim.api.nvim_win_get_width(win)
                      local col = math.floor((win_width - image_width) / 2)
                      if col < 0 then col = 0 end

                      if image then pcall(function() image:clear() end) end

                      image = require("image").from_file(dashboard_image_path, {
                        window = nil, 
                        buffer = alpha_buf,
                        width = image_width,
                        x = col,
                        y = row,
                        with_virtual_padding = false, 
                        clear_in_background = true,
                      })
                      
                      if image then pcall(function() image:render() end) end
                    end)
                  end

                  vim.api.nvim_create_autocmd("User", {
                    pattern = "AlphaReady",
                    group = alpha_image_group,
                    callback = function()
                      vim.go.laststatus = 0
                      vim.opt.showtabline = 0
                      render_dashboard_image()
                    end,
                  })

                  vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter", "WinResized", "TextChanged", "VimResized" }, {
                    buffer = alpha_buf,
                    group = alpha_image_group,
                    callback = function()
                      if vim.api.nvim_get_current_buf() ~= alpha_buf then return end
                      vim.cmd("redraw")
                      render_dashboard_image()
                    end,
                  })

                  vim.api.nvim_create_autocmd({ "BufLeave", "BufUnload", "BufHidden" }, {
                    buffer = alpha_buf,
                    callback = function()
                      vim.go.laststatus = 3
                      vim.opt.showtabline = 2
                      pcall(function() vim.api.nvim_del_augroup_by_id(alpha_image_group) end)
                      pcall(function() require("image").clear() end)
                      image = nil
                      vim.cmd("redraw!")
                    end,
                  })
                end,
              },
            })
          '';
        };
      };

      extraPlugins = [
        pkgs.vimPlugins.nvim-window-picker
      ];

      extraConfigLua = ''
        require("window-picker").setup({
          filter_rules = {
            bo = {
              filetype = { "neo-tree", "neo-tree-popup", "notify", "edgy", "toggleterm" },
              buftype = { "terminal", "quickfix" },
            },
          },
        })
      '';
    };
  };
}
