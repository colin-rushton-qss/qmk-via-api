{
  inputs = {
     rust-overlay.url = "github:oxalica/rust-overlay/stable";
    cargo2nix = {
      url = "github:cargo2nix/cargo2nix/release-0.12";
      inputs.rust-overlay.follows = "rust-overlay";
    };
    flake-utils.follows = "cargo2nix/flake-utils";
    nixpkgs.follows = "cargo2nix/nixpkgs";
  };

  outputs = inputs: with inputs;
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [cargo2nix.overlays.default];
        };

        rustPkgs = pkgs.rustBuilder.makePackageSet {
          rustVersion = "1.89.0";
          packageFun = import ./Cargo.nix;
          packageOverrides = pkgs: pkgs.rustBuilder.overrides.all ++ [
            # parentheses disambiguate each makeOverride call as a single list element
            (pkgs.rustBuilder.rustLib.makeOverride {
                name = "hidapi";
                overrideAttrs = drv: {
                  propagatedBuildInputs = drv.propagatedBuildInputs or [ ] ++ [
                    pkgs.pkg-config
                    pkgs.udev
                  ];
                };
            })
          ];
        };

      in rec {
        packages = {
          qmk-via-api = (rustPkgs.workspace.qmk-via-api {});
          default = packages.qmk-via-api;
        };
      }
    );
}