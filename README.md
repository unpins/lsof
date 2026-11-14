# lsof

[lsof](https://github.com/lsof-org/lsof) — list open files. A single self-contained binary, built natively for Linux and macOS.

[![CI](https://github.com/unpins/lsof/actions/workflows/lsof.yml/badge.svg)](https://github.com/unpins/lsof/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install lsof`.

## Usage

Run the `lsof` program with [unpin](https://github.com/unpins/unpin):

```bash
unpin lsof -i :80         # what is listening on port 80
unpin lsof -p 1234        # files opened by PID 1234
unpin lsof /var/log       # which processes have files open under /var/log
```

To install it onto your PATH:

```bash
unpin install lsof
```

## Man pages

`lsof.8` is embedded in the binary — read it with `unpin man lsof`.

## Build locally

```bash
nix build github:unpins/lsof
./result/bin/lsof -v
```

Or run directly:

```bash
nix run github:unpins/lsof -- -v
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/lsof/releases) page has standalone binaries for manual download.

## Build notes

- **Platforms:** Linux and macOS. lsof has no Windows port upstream.
- **RPC program names:** on macOS, `lsof -i` names the RPC programs registered
  with the portmapper. On Linux it shows the numbers instead, as nixpkgs' lsof
  does: the names would come from libtirpc, which neither links on Linux.
