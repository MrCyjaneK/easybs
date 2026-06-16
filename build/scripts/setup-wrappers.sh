#!/bin/bash
set -euxo pipefail

: "${STAGING:?STAGING must be set}"
: "${CLANG_VERSION:?CLANG_VERSION must be set}"

BIN="$STAGING/bin"
REAL_CLANG="clang-${CLANG_VERSION}"
REAL_CLANGXX="clang++-${CLANG_VERSION}"

rm -f "$BIN/clang" "$BIN/clang++"

DASH_BOOT='ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -z "${EASYBS_DASH_WRAPPER-}" ]; then
  export EASYBS_DASH_WRAPPER=1
  exec "$ROOT/bin/dash" "$0" "$@"
fi'

LINK_CHECK='link=1
has_input=0
for arg in "$@"; do
  case $arg in
    -c|-E|-S|-M|-MM|-fsyntax-only|--precompile) link=0 ;;
    -v|-###|--version|-V|-dumpversion|-dumpmachine|-dumpfullversion) link=0 ;;
    -print-search-dirs|-print-file-name=*|-print-prog-name=*|-print-libgcc-file-name) link=0 ;;
    -?*) ;;
    *) has_input=1 ;;
  esac
done
if [ "$has_input" -eq 0 ]; then
  link=0
fi'

if [[ -n "${TARGET_TRIPLE:-}" ]]; then
  # clang --gcc-toolchain must not resolve bin/gcc to this wrapper (simplybs symlinks
  # gcc->clang for ct-ng). Keep real GCC drivers under libexec/gcc-toolchain instead.
  GUARD="if [ -n \"\${EASYBS_CLANG_GUARD-}\" ]; then
  real_gcc=\"\$ROOT/libexec/gcc-toolchain/bin/${TARGET_TRIPLE}-gcc\"
  if [ -x \"\$real_gcc\" ]; then
    exec \"\$real_gcc\" \"\$@\"
  fi
  echo \"clang wrapper: recursive gcc invocation\" >&2
  exit 1
fi
export EASYBS_CLANG_GUARD=1"

  GCC_DELEGATE='for arg in "$@"; do
  case $arg in
    -print-multi-os-directory|-print-multi-directory|-print-sysroot-headers-suffix)
      real_gcc="$ROOT/libexec/gcc-toolchain/bin/'"${TARGET_TRIPLE}"'-gcc"
      if [ -x "$real_gcc" ]; then exec "$real_gcc" "$@"; fi
      exit 1
      ;;
  esac
done'

  GXX_DELEGATE='for arg in "$@"; do
  case $arg in
    -print-multi-os-directory|-print-multi-directory|-print-sysroot-headers-suffix)
      real_gxx="$ROOT/libexec/gcc-toolchain/bin/'"${TARGET_TRIPLE}"'-g++"
      if [ -x "$real_gxx" ]; then exec "$real_gxx" "$@"; fi
      exit 1
      ;;
  esac
done'

  # Linux: sysroot + GCC runtime (libstdc++, libgcc, crt).
  LINUX_BASE="-target ${TARGET_TRIPLE} \\
    --sysroot=\"\$ROOT/sysroot\" \\
    --gcc-toolchain=\"\$ROOT/libexec/gcc-toolchain\" \\
    -B\"\$ROOT/libexec/gcc-toolchain/bin\""
  LINUX_LINK_EXTRA=""
  if [[ "${TARGET_CPU:-}" == aarch64 ]]; then
    LINUX_LINK_EXTRA="-latomic"
  fi

  cat >"$BIN/clang" <<EOF
#!/bin/sh
$DASH_BOOT
$GCC_DELEGATE
$GUARD
$LINK_CHECK
if [ "\$link" -eq 1 ]; then
  exec "\$ROOT/bin/${REAL_CLANG}" \\
    ${LINUX_BASE} \\
    -fuse-ld=lld \\
    ${LINUX_LINK_EXTRA} \\
    "\$@"
fi
exec "\$ROOT/bin/${REAL_CLANG}" \\
  ${LINUX_BASE} \\
  "\$@"
EOF

  cat >"$BIN/clang++" <<EOF
#!/bin/sh
$DASH_BOOT
$GXX_DELEGATE
$GUARD
$LINK_CHECK
if [ "\$link" -eq 1 ]; then
  exec "\$ROOT/bin/${REAL_CLANGXX}" \\
    ${LINUX_BASE} \\
    -stdlib=libstdc++ \\
    -fuse-ld=lld \\
    ${LINUX_LINK_EXTRA} \\
    "\$@"
fi
exec "\$ROOT/bin/${REAL_CLANGXX}" \\
  ${LINUX_BASE} \\
  -stdlib=libstdc++ \\
  "\$@"
EOF

  ln -sf ld.lld "$BIN/ld"
  ln -sf llvm-ar "$BIN/ar"
  ln -sf llvm-ranlib "$BIN/ranlib"
  ln -sf llvm-nm "$BIN/nm"
  ln -sf llvm-strip "$BIN/strip"
  ln -sf llvm-objcopy "$BIN/objcopy"
  ln -sf llvm-readelf "$BIN/readelf"

elif [[ -n "${SDK_VERSION:-}" ]]; then
  # macOS: Apple SDK + libc++.
  cat >"$BIN/clang" <<EOF
#!/bin/sh
$DASH_BOOT
SDK="\$ROOT/SDK/MacOSX${SDK_VERSION}.sdk"
$LINK_CHECK
if [ "\$link" -eq 1 ]; then
  exec "\$ROOT/bin/${REAL_CLANG}" \\
    -target arm64-apple-darwin \\
    -isysroot "\$SDK" \\
    -mmacosx-version-min=${OSX_MIN} \\
    -fuse-ld=lld \\
    "\$@"
fi
exec "\$ROOT/bin/${REAL_CLANG}" \\
  -target arm64-apple-darwin \\
  -isysroot "\$SDK" \\
  -mmacosx-version-min=${OSX_MIN} \\
  "\$@"
EOF

  cat >"$BIN/clang++" <<EOF
#!/bin/sh
$DASH_BOOT
SDK="\$ROOT/SDK/MacOSX${SDK_VERSION}.sdk"
$LINK_CHECK
if [ "\$link" -eq 1 ]; then
  exec "\$ROOT/bin/${REAL_CLANGXX}" \\
    -target arm64-apple-darwin \\
    -isysroot "\$SDK" \\
    -mmacosx-version-min=${OSX_MIN} \\
    -stdlib=libc++ \\
    -fuse-ld=lld \\
    "\$@"
fi
exec "\$ROOT/bin/${REAL_CLANGXX}" \\
  -target arm64-apple-darwin \\
  -isysroot "\$SDK" \\
  -mmacosx-version-min=${OSX_MIN} \\
  -stdlib=libc++ \\
  "\$@"
EOF

  ln -sf ld64.lld "$BIN/ld"
  ln -sf llvm-ar "$BIN/ar"
  ln -sf llvm-ranlib "$BIN/ranlib"
  ln -sf llvm-nm "$BIN/nm"
  ln -sf llvm-strip "$BIN/strip"
  ln -sf llvm-otool "$BIN/otool"
  ln -sf llvm-install-name-tool "$BIN/install_name_tool"

else
  echo "setup-wrappers.sh: set TARGET_TRIPLE (Linux) or SDK_VERSION (Darwin)" >&2
  exit 1
fi

chmod +x "$BIN/clang" "$BIN/clang++"
