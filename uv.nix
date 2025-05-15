# This creates a shell with a working uv.
# usage:
# nix-shell uv.nix
# uv run hello.py

let
  # nixos-24.11 from 2024-12-29:
  nixpkgs = fetchTarball {
    name = "nixpkgs";
    url = "https://github.com/NixOS/nixpkgs/archive/d49da4c0.tar.gz";
    sha256 = "02g0ivn1nd8kpzrfc4lpzjbrcixi3p8iysshnrdy46pnwnjmf1rj";
  };

  pkgs = import nixpkgs {};
  lib = pkgs.lib;

  python = pkgs.python313; # cargo does not work on 314

in

  pkgs.stdenvNoCC.mkDerivation {
    name = "shell";
    dontUnpack = "true";
    buildInputs = [
      python
      pkgs.uv
    ];

    env =  {
      UV_PYTHON_DOWNLOADS = "never";
      UV_PYTHON = python.interpreter;
      LD_LIBRARY_PATH = lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
    };

    # prevent nixpkgs from being garbage-collected
    inherit nixpkgs;

    # this lets you build a permanent shell with nix-build
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
