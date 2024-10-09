{
  description = "git-conflict.nvim";

  nixConfig = {
    extra-substituters = "https://neorocks.cachix.org";
    extra-trusted-public-keys = "neorocks.cachix.org-1:WqMESxmVTOJX7qoBC54TwrMMoVI1xAM+7yFin8NRfwk=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    neorocks.url = "github:nvim-neorocks/neorocks";
  };

  outputs =
    {
      nixpkgs,
      flake-parts,
      neorocks,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem =
        { system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              neorocks.overlays.default
            ];
          };
        in
        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              gnumake
              busted-nlua
              lua.pkgs.luacheck
              stylua
            ];
          };
          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
