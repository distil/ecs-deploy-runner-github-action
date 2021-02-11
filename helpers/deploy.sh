#!/bin/bash
#
# Script used by GitHub Actions to trigger deployments via the infrastructure-deployer CLI utility.
#
# Required positional arguments, in order:
# - AWS_ACCOUNT_ID : The ID of the AWS account where this is being deployed.
# - REGION : The AWS Region where the ECS Deploy Runner exists.
# - SOURCE_REF : The starting point for identifying all the changes. The diff between SOURCE_REF and REF will be
#                evaluated to determine all the changed files.
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
  local -r deploy_path="$6"

  local assume_role_exports
  assume_role_exports="$(aws-auth --role-arn "arn:aws:iam::$aws_account_id:role/allow-auto-deploy-from-other-accounts" --role-duration-seconds 3600)"

  local container
  if [[ "$command" == "plan" ]] || [[ "$command" == "plan-all" ]] || [[ "$command" == "validate" ]] || [[ "$command" == "validate-all" ]]; then
    container="terraform-planner"
  else
    container="terraform-applier"
  fi

  (eval "$assume_role_exports" && \
    infrastructure-deployer --aws-region "$region" -- "$container" infrastructure-deploy-script --repo "$repo" --ref "$ref" --binary "terragrunt" --command "$command" --deploy-path "$deploy_path")
}

function run {
  local -r aws_account_id="$1"
  local -r region="$2"
  local -r source_ref="$3"
  local -r repo="$4"
  local -r ref="$5"
  local -r command="$6"

  # We must export the function so that it can be invoked through xargs
  export -f invoke_infrastructure_deployer

  # Use git-updated-folders to find all the terragrunt modules that changed, and pipe that through to the
  # infrastructure-deployer.
  # The last step is a check to see if there was any output from the previous command, which will be empty if no
  # modules were updated.
  git-updated-folders --source-ref "$source_ref" --terragrunt --repo-root "$GITHUB_WORKSPACE" \
    | xargs -I{} --no-run-if-empty \
        bash -c "invoke_infrastructure_deployer \"$aws_account_id\" \"$region\" \"$repo\" \"$ref\" \"$command\" {}" \
    |& bash -c "grep . || echo 'No terragrunt modules were updated. Skipping plan.'"
}

run "$@"