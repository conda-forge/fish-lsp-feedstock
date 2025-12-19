#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# Do not use tree-sitter, not really needed
jq 'del(.dependencies["tree-sitter"])' package.json > tmp && mv tmp package.json

# Create package archive and install globally
npm pack --ignore-scripts
npm install -ddd --global --no-bin-links --build-from-source ${SRC_DIR}/${PKG_NAME}-${PKG_VERSION//_/-}.tgz

# Create license report for dependencies
pnpm install
pnpm-licenses generate-disclaimer --prod --output-file=third-party-licenses.txt

mkdir -p ${PREFIX}/bin
tee ${PREFIX}/bin/fish-lsp <<EOF
#!/bin/sh
exec \${CONDA_PREFIX}/lib/node_modules/fish-lsp/dist/fish-lsp "\$@"
EOF
chmod +x ${PREFIX}/bin/fish-lsp

tee ${PREFIX}/bin/fish-lsp.cmd <<EOF
call %CONDA_PREFIX%\bin\node %CONDA_PREFIX%\lib\node_modules\fish-lsp\dist\fish-lsp %*
EOF
