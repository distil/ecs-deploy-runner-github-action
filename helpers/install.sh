#!/bin/bash
#
# Script used by GitHub Actions to install the necessary helpers for the CI/CD pipeline
#

set -euo pipefail

function run {
  local -r gruntwork_installer_version="$1"
  local -r terraform_aws_ci_version="$2"
  local -r terraform_aws_security_version="$3"

  curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh \
    | bash /dev/stdin --version "$gruntwork_installer_version"
  gruntwork-install --repo "https://github.com/gruntwork-io/terraform-aws-ci" \
    --binary-name "infrastructure-deployer" \
    --tag "$terraform_aws_ci_version"
  gruntwork-install --repo "https://github.com/gruntwork-io/terraform-aws-ci" \
    --module-name "terraform-helpers" \
    --tag "$terraform_aws_ci_version"
  gruntwork-install --repo "https://github.com/gruntwork-io/terraform-aws-security" \
    --module-name "aws-auth" \
    --tag "$terraform_aws_security_version"
}

run "$@"