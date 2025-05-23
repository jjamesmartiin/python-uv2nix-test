# This uses uv2nix to open a shell with all the uv packages already
# loaded.

let
  # nixos-24.11 from 2024-12-29:
  nixpkgs = fetchTarball {
    name = "nixpkgs";
    url = "https://github.com/NixOS/nixpkgs/archive/d49da4c0.tar.gz";
    sha256 = "02g0ivn1nd8kpzrfc4lpzjbrcixi3p8iysshnrdy46pnwnjmf1rj";
  };

  pkgs = import nixpkgs {};

  lib = pkgs.lib;

  pyproject-nix = import (builtins.fetchGit {
    url = "https://github.com/pyproject-nix/pyproject.nix.git";
  }) {
    inherit lib;
  };

  uv2nix = import (builtins.fetchGit {
    url = "https://github.com/pyproject-nix/uv2nix.git";
  }) {
    inherit pyproject-nix lib;
  };

  pyproject-build-systems = import (builtins.fetchGit {
    url = "https://github.com/pyproject-nix/build-system-pkgs.git";
  }) {
    inherit pyproject-nix uv2nix lib;
  };

  python = pkgs.python313; # cargo does not work on 314

  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

  uvLockedOverlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  pythonSet =
    # Use base package set from pyproject.nix builders
    (pkgs.callPackage pyproject-nix.build.packages {
      inherit python;
    })
      .overrideScope (pkgs.lib.composeManyExtensions [
        pyproject-build-systems.default
        uvLockedOverlay
      ]);

  virtualenv = pythonSet.mkVirtualEnv "python-test" workspace.deps.all;

in

  pkgs.stdenvNoCC.mkDerivation {
    name = "shell";
    dontUnpack = "true";
    buildInputs = [
      virtualenv
    ];

    env =  {
      UV_PYTHON_DOWNLOADS = "never";
      UV_PYTHON = python.interpreter;
      LD_LIBRARY_PATH = lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
    };

    # prevent nixpkgs from being garbage-collected
    inherit nixpkgs;

    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup
      eval $shellHook

      {
        echo "#!$SHELL"
        for var in PATH SHELL nixpkgs
        do echo "declare -x $var=\"''${!var}\""
        done
        echo "declare -x PS1='\n\033[1;32m[nix-shell:\w]\$\033[0m '"
        echo "exec \"$SHELL\" --norc --noprofile \"\$@\""
      } > "$out"

      chmod a+x "$out"
    '';
  }
