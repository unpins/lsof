{
  description = "lsof as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # lsof lists open files by reading the kernel's view of every process —
  # /proc on Linux, libproc on macOS. There is no Windows equivalent (no
  # /proc, no global fd table to walk), so this is a Linux + macOS package.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "lsof";
      smoke = [ "-v" ];
      smokePattern = "revision: [0-9]+\\.[0-9]+";

      # Build via the unpin-llvm engine + emit a bitcode multicall module.
      engine = "unpin-llvm";
      multicall = {
        programs = [{ name = "lsof"; }];
      };
      build = pkgs:
        let
          p = pkgs.pkgsStatic;
          isLinux = pkgs.stdenv.hostPlatform.isLinux;
          # lsof's Configure probes optional features by testing
          # `-r $LSOF_INCLUDE/<header>` -- one prefix for everything. On a
          # distribution that is /usr/include and every header is there; here
          # each library has its own store prefix, so selinux/selinux.h was
          # never found and Configure dropped SELinux support in silence. The
          # man page we embed documents `-Z`, and the binary answered
          # `illegal option character: Z`.
          #
          # RPC (the other header probe, tirpc/rpc/rpc.h) is NOT reachable
          # here and this is a libc limit, not a packaging one: lsof calls
          # `getrpcbynumber`, which lives in glibc's NSS, not in libtirpc --
          # Debian's lsof imports it from libc. musl has no RPC database, so
          # the Linux build cannot name RPC programs. The macOS build can and
          # does; its SDK carries both.
          lsofIncludes = pkgs.symlinkJoin {
            name = "lsof-include";
            paths = map (x: "${pkgs.lib.getDev x}/include")
              [ p.musl p.libselinux ];
          };
        in
        p.lsof.overrideAttrs (old: {
          # nixpkgs sets `env.LSOF_INCLUDE = "${lib.getDev stdenv.cc.libc}/include"`
          # to point lsof's Configure at the system headers. The unpin-llvm engine
          # cc-wrapper is built with `libc = null` (it carries its libc headers in
          # the toolchain sysroot), so `stdenv.cc.libc` is null and the default
          # interpolation coerces null → eval error on BOTH platforms. Point it at
          # the target libc's dev headers explicitly: musl on Linux, the macOS SDK
          # (the same sysroot the engine feeds clang via SDKROOT) on Darwin. The
          # value only seeds a `s,/usr/include,$LSOF_INCLUDE,` rewrite, and the
          # engine resolves the real headers via its sysroot regardless.
          env = old.env // {
            LSOF_INCLUDE =
              if isLinux
              then "${lsofIncludes}"
              else "${pkgs.apple-sdk.sdkroot}/usr/include";
          };
          buildInputs = (old.buildInputs or [ ])
            ++ pkgs.lib.optionals isLinux [ p.libselinux ];
          # lsof bakes its build CFLAGS into version.h so `lsof -v` can echo
          # them. That string includes the musl `-I<libc-dev>/include` path.
          # nixpkgs already runs `nuke-refs version.h`, which blanks the hash
          # to a dead `eeee…` placeholder (so it's not a real store reference)
          # — but the literal `/nix/store/…` text remains, which trips our
          # "no store strings in the binary" bar. Drop the whole `-I/nix/store/…`
          # token: `lsof -v` then shows clean flags and the binary carries no
          # store string. (postPatch already removed version.h's FRC rebuild
          # trigger, so the main `make` won't regenerate it after this edit.)
          preBuild = (old.preBuild or "") + ''
            sed -i 's#-I/nix/store/[^ "]*##g' version.h
          '';
          # ncurses is a buildInput (macOS links -lncurses for its curses-based
          # output; Linux doesn't link it but still gets it on the include
          # path). Its `-dev` output leaks into
          # $out/nix-support/propagated-build-inputs as a reference. A leaf
          # binary propagates nothing — drop the metadata so the closure is
          # empty.
          postFixup = (old.postFixup or "") + ''
            rm -rf "$out/nix-support"
          '';
        });
    };
}
