This uses uv2nix to open a shell with all the uv packages already
loaded.

Usage:

```sh
$ nix-shell

... lots of output the first time ...

[nix-shell]$ python hello.py

Hello from python-test!
Testing httpx...<Response [200 OK]>

[nix-shell]$
```

To build a permanent shell, run

```sh
nix-build -o shell
```

For a shell with just uv by itself (for example if the uv2nix shell is
broken), run

```sh
nix-shell -A uv
```

To add a new package?
```sh
# yfinance


uv add yfinance
nix-shell
# fails
#       > error: Build backend failed to build wheel through `build_wheel` (exit status: 1)
#       For full logs, run:
#         nix log /nix/store/608xrch0r3y1b66h05bbhw1791nyk53r-peewee-3.18.1.drv
#
#
# can't even get back to the shell because uv2nix is broken and can't build
# we have to remove yfinance (basically all my changes) from:
    # .toml?
    # uv.lock
# reading https://nixos.org/manual/nixpkgs/stable/#python 
# 
# trying to add python312Packages.yfinance to build inputs

```
