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

- **Platforms:** Linux and macOS. lsof walks the kernel's per-process open-file
  tables — `/proc` on Linux, `libproc` on macOS. Windows has no equivalent
  (no `/proc`, no global file-descriptor table to enumerate), so there is no
  mingw/cosmopolitan build.
- **RPC program names:** on macOS, `lsof -i` names the RPC programs registered
  with the portmapper. On Linux it shows the numbers instead — that lookup
  lives in glibc, and this binary is built against musl so that it runs on any
  distribution.
- **0-ref:** lsof embeds its build `CFLAGS` into the binary so `lsof -v` can
  echo them; that string carried the musl `-I<libc>/include` path. nixpkgs
  already blanks the store hash, and we strip the whole `-I/nix/store/…` token
  so the binary holds no store reference at all.
