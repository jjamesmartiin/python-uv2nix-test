# This uses uv2nix to open a shell with all the uv packages already
# loaded.

let
  ### nixos-24.11 from 2024-12-29:
  nixpkgs = fetchTarball {
    name = "nixpkgs";
    url = "https://github.com/NixOS/nixpkgs/archive/d49da4c0.tar.gz";
    sha256 = "02g0ivn1nd8kpzrfc4lpzjbrcixi3p8iysshnrdy46pnwnjmf1rj";
  };

  pkgs = import nixpkgs {};
  lib = pkgs.lib;

  # Supposedly cargo does not work on 314 so stick to 313.
  python = pkgs.python313;

  ### Get the latest versions of uv2nix and dependencies from 2025-05-22:

  pyproject-nix = import (fetchTarball {
    name = "pyproject.nix";
    url = "https://github.com/pyproject-nix/pyproject.nix/archive/e09c10c.tar.gz";
    sha256 = "sha256:10ql65kmw8zvdrcaj9q4nbzrh5v7gry56ylvqcmw52avv8c4f5s3";
  }) {
    inherit lib;
  };

  uv2nix = import (fetchTarball {
    name = "";
    url = "https://github.com/pyproject-nix/uv2nix/archive/ec05022.tar.gz";
    sha256 = "sha256:0gc20q097zrixxcnpik7bxiv11k5qwc42rki1p3jnl5hfca15zyn";
  }) {
    inherit pyproject-nix lib;
  };

  pyproject-build-systems = import (builtins.fetchGit {
    url = "https://github.com/pyproject-nix/build-system-pkgs.git";
  }) {
    inherit pyproject-nix uv2nix lib;
  };

  ### Required setup for a venv with uv2nix

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
      pkgs.uv # optional; not required to just run python code
      python # for running uv
    ];

    env =  {
      UV_PYTHON_DOWNLOADS = "never";
      UV_PYTHON = python.interpreter;
      LD_LIBRARY_PATH = lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
    };

    # Prevent nixpkgs from being garbage-collected when building a
    # permanent shell.
    inherit nixpkgs;

    motd = ''
      This is a uv2nix shell with Python ${python.version}.
      You can also run `nix-shell -A uv` to get uv by itself.
      Run binaries with `python hello.py`.
      To build a permanent shell, run `nix-build`.'';

    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup
      eval "$shellHook"

      {
        echo "#!$SHELL"
        for var in PATH SHELL nixpkgs
        do echo "declare -x $var=\"''${!var}\""
        done
        echo "declare -x PS1='\n\033[1;32m[nix-shell:\w]\$\033[0m '"
        echo "eval \"$shellHook\""
        echo "exec \"$SHELL\" --norc --noprofile \"\$@\""
      } > "$out"

      chmod a+x "$out"
    '';

    shellHook = ''
      echo
      echo "$motd"
      if [ -d .venv ]
      then
        echo "Warning: .venv/ exists and can be removed."
      fi
    '';

  } //
  {
    # Run with `nix-shell -A uv` to get a shell with uv and python,
    # to install and upgrade packages when the main shell is broken.
    uv =
      pkgs.mkShell {
        packages = [
          pkgs.uv
          python
        ];
      };
  }
