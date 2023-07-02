{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:gytis-ivaskevicius/flake-utils-plus";
    nixvim = {
      url = "github:pta2002/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, utils, nixvim }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nixvimLib = nixvim.lib.${system};
        nixvim' = nixvim.legacyPackages.${system};
        neovim = nixvim'.makeNixvim {
          options = {
            number = true; # Show line numbers
            relativenumber = true; # Show relative line numbers
            shiftwidth = 2; # Tab width should be 2
          };
          highlight = {
            Comment = {
              italic = true;
              fg = "grey";
            };
            Keyword = {
              italic = true;
              fg = "#fb4934";
            };
            Type = {
              fg = "#fabd2f";
            };
            Structure = {
              fg = "#fabd2f";
            };
            Macro = {
              italic = true;
              fg = "#b16286";
            };
            Operator = {
              italic = true;
              fg = "#d3869b";
            };
          };
          plugins = {
            telescope.enable = true;
            nix.enable = true;
            nvim-autopairs.enable = true;
            lualine = {
              enable = true;
              sectionSeparators = {
                left = "";
                right = "";
              };
              componentSeparators = {
                left = "";
                right = "";
              };
              theme = "auto";
            };
            coq-nvim = {
              enable = true;
              autoStart = true;
              recommendedKeymaps = true;
              installArtifacts = true;
            };
            goyo = {
              enable = true;
              showLineNumbers = false;
            };
            lsp = {
              enable = true;
              servers = {
                rust-analyzer.enable = true;
                rnix-lsp.enable = true;
              };

            };
            noice.enable = true;
            treesitter = {
              enable = true;
              ensureInstalled = [ "nix" "rust" ];
            };
            bufferline.enable = true;
            cursorline = {
              enable = true;
              cursorline.timeout = 0;
            };
            luasnip.enable = true;
            gitsigns.enable = true;
            which-key.enable = true;
          };
          # globals.mapleader = "<space>";
          maps = {
            normal."<space>t" = { action = ":Telescope<return>"; };
            normal."<space>f" = { action = ":Telescope find_files<return>"; };
            normal."<space>F" = { action = ":Telescope live_grep<return>"; };
          };
          extraPlugins = with pkgs.vimPlugins; [
            vim-nix
            gruvbox-community
            blamer-nvim
            nvim-treesitter-parsers.wgsl
            nvim-treesitter-parsers.wgsl_bevy
            harpoon
            vim-fugitive
          ];
          extraConfigLua = builtins.readFile ./init.lua;
          extraConfigVim = builtins.readFile ./init.vim;
        };

        config_dir = pkgs.runCommand "nvim-config" { } ''
          mkdir $out
          cd $out
          ln -s ${self} nvim
        '';
      in
      {
        packages = rec {
          nvim = pkgs.writeShellApplication {
            name = "nvim";

            runtimeInputs = with pkgs; [ ripgrep ];

            text = ''
              XDG_CONFIG_HOME=${config_dir}
              export XDG_CONFIG_HOME=${config_dir}
              ${neovim}/bin/nvim "$@"
            '';
          };
          default = nvim;
        };

        checks = {
          # Run `nix flake check .` to verify that your config is not broken
          default = nixvimLib.check.mkTestDerivationFromNvim {
            inherit neovim;
            name = "A nixvim configuration";
          };
        };

        apps = rec {
          nvim = utils.lib.mkApp {
            drv = self.packages.${system}.nvim;
            name = "nvim";
          };
          default = nvim;
        };
      });
}
