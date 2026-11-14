{
  description = "lsof as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Linux and macOS: lsof has no Windows port upstream.
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
          # RPC (the other header probe, rpc/rpc.h or tirpc/rpc/rpc.h) stays
          # off on Linux, as in nixpkgs: its lsof has no libtirpc, and glibc no
          # longer ships rpc/rpc.h. The way in would be libtirpc built with
          # --enable-rpcdb (for `getrpcbynumber`); not tried. The macOS SDK
          # carries both.
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
          # the target's headers explicitly: the `lsof-include` join above on
          # Linux, the macOS SDK (the same sysroot the engine feeds clang via
          # SDKROOT) on Darwin. Configure's `-r $LSOF_INCLUDE/<header>` probes
          # read it, and it becomes `-I$LSOF_INCLUDE` (LSOF_DINC) in the compile.
          env = old.env // {
            LSOF_INCLUDE =
              if isLinux
              then "${lsofIncludes}"
              else "${pkgs.apple-sdk.sdkroot}/usr/include";
          };
          buildInputs = (old.buildInputs or [ ])
            ++ pkgs.lib.optionals isLinux [ p.libselinux ];
          # lsof bakes its build CFLAGS into version.h so `lsof -v` can echo
          # them. That string includes the `-I<lsof-include>` path.
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
        });
    };
}
