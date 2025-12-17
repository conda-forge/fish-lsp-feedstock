#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

export PYTHON=${BUILD_PREFIX}/bin/python

# Create package archive and install globally
case "${target_platform}" in
  osx-arm64|linux-aarch64) export npm_config_arch="arm64" ;;
esac

if [[ "${build_platform}" != "${target_platform}" ]]; then
    rm $PREFIX/bin/node
    ln -s $BUILD_PREFIX/bin/node $PREFIX/bin/node
fi

# Do not use tree-sitter, not really needed
jq 'del(.dependencies["tree-sitter"])' package.json > tmp && mv tmp package.json

# Create package archive and install globally
npm pack
npm install -ddd --global ${SRC_DIR}/${PKG_NAME}-${PKG_VERSION//_/-}.tgz

# Create license report for dependencies
pnpm install
pnpm-licenses generate-disclaimer --prod --output-file=third-party-licenses.txt

rm -rf ${PREFIX}/lib/node_modules/fish-lsp/node_modules/tree-sitter/build
