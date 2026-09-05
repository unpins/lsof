# Changelog

## [Unreleased]

### Fixed

- The `-Z` option, which lists the SELinux security context of each process,
  did not exist on Linux. It is documented in the manual page that ships
  inside the binary, but the binary answered `illegal option character: Z`.
