#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. $SCRIPT_DIR/parse-command-line-args.sh <<EOT
[
    {
        "option": "n=|name|app-name",
        "required": true,
        "description": "A comma separated list of application names or the keyword 'all' to run the given build for all the relevant applications",
        "variable": "APP_NAME"
    },
    {
        "option": "number=",
        "required": true,
        "values": [100, 200, 300, 400],
        "description": "A number representing one of the AKS root modules",
        "variable": "NUMBER"
    },
    {
        "option": "k=|kind",
        "values": ["strict", "relaxed"],
        "default": "strict",
        "description": "The validation kind",
        "variable": "KIND"
    },
    {
        "option": "b=|build",
        "required": true,
        "description": "A build definition name",
        "variable": "BUILD_DEF_NAME"
    },
    {
        "option": "nn|no-navigate",
        "description": "Do not navigate to the build pages",
        "variable": "NO_NAVIGATE"
    },
    {
        "option": "p|plan",
        "description": "Plan only, do not apply",
        "variable": "TERRAFORM_PLAN"
    },
    {
        "option": "s|skip|skip-internal-dns",
        "description": "Skip the internal DNS stages",
        "variable": "SKIP_INTERNAL_DNS"
    }
]
EOT

echo "APP_NAME=$APP_NAME"
echo "NUMBER=$NUMBER"
echo "BUILD_DEF_NAME=$BUILD_DEF_NAME"
echo "KIND=$KIND"
echo "NO_NAVIGATE=$NO_NAVIGATE"
echo "TERRAFORM_PLAN=$TERRAFORM_PLAN"
echo "SKIP_INTERNAL_DNS=$SKIP_INTERNAL_DNS"
