{
  description = "git-conflict.nvim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    gen-luarc = {
      url = "github:mrcjkb/nix-gen-luarc-json";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      gen-luarc,
      ...
    }:
    let
      nixpkgsFor =
        system:
        (import nixpkgs {
          inherit system;
          overlays = [
            gen-luarc.overlays.default
          ];
        });

      forAllSystems =
        function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ] (system: function (nixpkgsFor system));
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          fs = pkgs.lib.fileset;
          sourceFiles = fs.unions [
            ./lua
          ];
          git-conflict-nvim = pkgs.vimUtils.buildVimPlugin {
            src = fs.toSource {
              root = ./.;
              fileset = sourceFiles;
            };
            pname = "git-conflict-nvim";
            version = "latest";
            nvimRequireCheck = "git-conflict";
            runtimeDeps = [ pkgs.git ];
          };
        in
        {
          inherit git-conflict-nvim;
          default = git-conflict-nvim;
        }
      );

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          shellHook =
            let
              luarc = pkgs.mk-luarc-json { };
            in
            # bash
            ''
              ln -fs ${luarc} .luarc.json
            '';
          packages = with pkgs; [
            gnumake
            luajitPackages.busted
            luajitPackages.luacheck
            luajitPackages.nlua
            stylua
          ];
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
