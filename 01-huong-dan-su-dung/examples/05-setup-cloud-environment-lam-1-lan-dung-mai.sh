#!/bin/bash
# Node monorepo:
set -eux
corepack enable
pnpm install --frozen-lockfile
pnpm build
echo "CLOUD_ENV_READY=1"
