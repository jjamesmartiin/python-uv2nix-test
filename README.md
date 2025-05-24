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
