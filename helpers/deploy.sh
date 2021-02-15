#!/bin/bash
#
# Script used by GitHub Actions to trigger deployments via the infrastructure-deployer CLI utility.
#
# Required positional arguments, in order:
# - AWS_ACCOUNT_ID : The ID of the AWS account where this is being deployed.
# - REGION : The AWS Region where the ECS Deploy Runner exists.
# - REPO : Repository that is being deployed.
# - REF : The end point for identifying all the changes. The diff between SOURCE_REF and REF will be evaluated to
#         determine all the changed files.
# - COMMAND : The command to run. Should be one of plan or apply.
#

set -euxo pipefail

# Function that invoke the ECS Deploy Runner using the infrastructure-deployer CLI. This will also make sure to assume
# the correct IAM role.
function invoke_infrastructure_deployer {
  local -r aws_account_id="$1"
  local -r region="$2"
  local -r repo="$3"
  local -r ref="$4"
  local -r command="$5"

  local assume_role_exports
  assume_role_exports="$(aws-auth --role-arn "arn:aws:iam::$aws_account_id:role/allow-auto-deploy-from-other-accounts" --role-duration-seconds 3600)"

  local container
  if [[ "$command" == "plan" ]] || [[ "$command" == "plan-all" ]] || [[ "$command" == "validate" ]] || [[ "$command" == "validate-all" ]]; then
    container="terraform-planner"
  else
    container="terraform-applier"
  fi

  (eval "$assume_role_exports" && \
    infrastructure-deployer --aws-region "$region" -- "$container" infrastructure-deploy-script --repo "$repo" --ref "$ref" --binary "terragrunt" --command "$command")
}

invoke_infrastructure_deployer "$@"