{
  description = "PFM NUR Repository";

  inputs = {
    ## --- Nixpkgs ---
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11-small";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    ## --- Flake ---
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-stable";
    };
    ## --- Tools ---
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    let
      lib = inputs.nixpkgs-stable.lib;
      modulesDir = ./modules;
      getNixFiles =
        dir:
        lib.flatten (
          lib.mapAttrsToList (
            name: type:
            let
              path = dir + "/${name}";
            in
            if type == "directory" then
              getNixFiles path
            else if type == "regular" && lib.hasSuffix ".nix" name then
              [ path ]
            else
              [ ]
          ) (builtins.readDir dir)
        );
      allModuleFiles = if builtins.pathExists modulesDir then getNixFiles modulesDir else [ ];

    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.treefmt-nix.flakeModule ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        { system, pkgs, ... }:
        let
          pkgsPath = ./pkgs;
          pkgFolders = pkgs.lib.filterAttrs (name: type: type == "directory") (builtins.readDir pkgsPath);
        in
        {
          _module.args.pkgs = import inputs.nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = pkgs.lib.meta.availableOn pkgs.stdenv.buildPlatform pkgs.nixfmt-rfc-style.compiler;
            programs.nixfmt.package = pkgs.nixfmt-rfc-style;
            programs.nixfmt.strict = true;
            programs.nixfmt.width = 120;
            programs.shfmt.enable = true;
            programs.shfmt.indent_size = 2;
            programs.shellcheck.enable = true;
            settings.formatter.shellcheck.options = [
              "-s"
              "bash"
            ];
            programs.taplo.enable = true;
            programs.prettier.enable = true;
            programs.prettier.settings = {
              tabWidth = 2;
              useTabs = false;
              printWidth = 120;
            };
            programs.just.enable = true;
            programs.fish_indent.enable = true;
          };
          packages = pkgs.lib.mapAttrs (name: _: pkgs.callPackage (pkgsPath + "/${name}") { }) pkgFolders;
        };

      flake = {
        nixosModules.default =
          { pkgs, ... }:
          {
            imports = allModuleFiles;
            nixpkgs.overlays = [ (final: prev: { pfm = self.packages.${pkgs.stdenv.hostPlatform.system}; }) ];
          };
      };

    };
}
