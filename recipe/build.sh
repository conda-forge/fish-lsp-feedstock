#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# Make node-gyp use the Node headers shipped in the conda package
export npm_config_nodedir="$PREFIX"

# Sometimes npm doesn’t forward python to node-gyp reliably:
export npm_config_python="${PYTHON}"

# Force building from source instead of chasing prebuilds
export npm_config_build_from_source=true

# Ensure deterministic, writable caches
export HOME="$PWD"
export npm_config_cache="$PWD/.npm-cache"

# Ensure node-gyp picks up conda-forge compilers and the macOS SDK
export CFLAGS="${CFLAGS} -isysroot ${CONDA_BUILD_SYSROOT}"
export CXXFLAGS="${CXXFLAGS} -isysroot ${CONDA_BUILD_SYSROOT}"
export LDFLAGS="${LDFLAGS} -Wl,-syslibroot,${CONDA_BUILD_SYSROOT}"

# Create package archive and install globally
case "${target_platform}" in
  osx-arm64|linux-aarch64) export npm_config_arch="arm64" ;;
esac

if [[ "${build_platform}" != "${target_platform}" ]]; then
    rm $PREFIX/bin/node
    ln -s $BUILD_PREFIX/bin/node $PREFIX/bin/node
fi

# Fix package.json so it can bootstrap itself
# Remove prepare script because it tries to call husky
# Remove compile command from post install script so we don't try to transpile typescript again
mv package.json package.json.bak
jq 'del(.scripts.prepare)' package.json.bak > package.json
sed -i 's/setup compile sh:relink/setup sh:relink/' package.json

# Create package archive and install globally
npm pack --ignore-scripts
npm install -ddd \
    --global \
    --build-from-source \
    ${SRC_DIR}/${PKG_NAME}-${PKG_VERSION//_/-}.tgz

# Create license report for dependencies
pnpm install --ignore-scripts
pnpm-licenses generate-disclaimer --prod --output-file=third-party-licenses.txt

rm -rf ${PREFIX}/lib/node_modules/fish-lsp/node_modules/tree-sitter/build
