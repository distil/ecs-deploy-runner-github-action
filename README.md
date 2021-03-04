# GitHub Action for invoking the ECS deploy runner

This repository contains a GitHub action that allows the user to easily invoke the Gruntwork ECS deploy runner from any
repository that requires it. This is heavily based on
[*How to configure a production-grade CI-CD workflow for infrastructure code*](https://gruntwork.io/guides/automations/how-to-configure-a-production-grade-ci-cd-setup-for-apps-and-infrastructure-code/).

# Table of Contents

- [Usage](#usage)
- [Examples](#examples)
- [Links](#links)
- [To Do](#to-do)

## Usage

### Setup

- The workflow name must match the deploy path of the Terragrunt code that is being deployed.
- The following environment variables must be set:
  - `AWS_ACCOUNT_ID` - the AWS account ID where the ECS deploy runner is deployed
    - Make sure this is enclosed in double quotes as otherwise leading zeros will be trimmed.
  - `AWS_REGION` - region where the ECS deploy runner is deployed.
  - `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` - AWS credentials for the machine user that invokes the ECS deploy
    runner.
  - `GITHUB_OAUTH_TOKEN` - GitHub personal auth token that can be used to reach Gruntworks repositories.
- A mandatory input variable `command` that currently accepts the following values to execute the respective
  `terragrunt` commands via the ECS deploy runner:
  - `plan` and `plan-all`
  - `apply` and `apply-all`

The action also accepts the following optional inputs:

- Versions of the following Gruntwork tools and modules (defaults can be viewed in `action.yaml`):
  - `gruntwork-installer-version`
  - `terraform-aws-ci-version`
  - `terraform-aws-security-version`
- The name of the main branch of the repository can be set via the following option (defaults to `main`):
  - `main-branch-name`

### Components

The action does the following:

1. Sets the `FRIENDLY_REF` environment variable based on whether the event that triggered the workflow is a pull request
   or a push to the main branch. This is done by looking for the `GITHUB_HEAD_REF` environment variable - it only exists
   on pull requests, and in that case the `FRIENDLY_REF` is set to the checksum of the head commit in the pull request.
   Otherwise, the `FRIENDLY_REF` is set to the head commit on the main branch.
2. It installs Gruntworks tools via a helper script. A Gruntworks subscription is required for this.
3. It executes Terragrunt using the `infrastructure-deploy-script` via the Gruntworks `infrastructure-deployer` CLI.
   Other tools that come with the standard Gruntworks ECS Deploy Runner configuration are not yet supported.

## Examples

Below is an example of a workflow that executes `terragrunt plan-all` on pull requests and pushes to `main`, and 
executes a `terragrunt apply-all` on pushes to `main`. It utilizes [GitHub Environments](https://docs.github.com/en/actions/reference/environments)
that can be used to more granularly set environment variables, and set up environment protection rules. Furthermore,
this workflow will only execute when a specific path is changed in a commit, thus avoiding unnecessary workflow runs
where no changes occurred.

The Terragrunt code is expected to be stored in directory `test-123456789123/us-east-1/dev` of the repository.

**NOTE**: `fetch-depth: 0` is required on the `checkout` action, as otherwise the ECS Deploy Runner task container
won't be able to see all the branches on pull requests.

```yaml
# The name of the workflow - this should match the path where the configuration to be deployed is kept
name: test-123456789123/us-east-1/dev
on:
  # Trigger the workflow on pushes to the main branch
  push:
    branches:
      - main
    paths:
      # Optional, but recommended - only trigger this workflow on commits to this path
      - 'test-123456789123/us-east-1/dev/**'
  
  # Trigger the workflow on all pull requests
  pull_request:
    paths:
      # Optional, but recommended - only trigger this workflow on commits to this path
      - 'test-123456789123/us-east-1/dev/**'

# Required environment variables
env:
  AWS_ACCOUNT_ID: "123456789123"  # AWS account ID into which the configuration is being deployed
  AWS_REGION: "us-east-1"  # AWS region that hosts the ECS Deploy Runner
  GITHUB_OAUTH_TOKEN: ${{ secrets.GRUNTWORK_OAUTH_TOKEN }}  # GitHub personal access token with access to Gruntwork

jobs:

  # This job performs a terragrunt plan-all
  plan:
    # Optional - define the GitHub Environment in which this job is executed. This is useful for things such as setting
    # environment-specific variables such as AWS credentials
    environment:  
      name: test-123456789123
    # Job specific environment variables - recommended to be populated from the GitHub environment assigned to the job
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    runs-on: ubuntu-latest

    steps:
      # Check out the repository
      - name: checkout
        uses: actions/checkout@v2
        with:
          # Use fetch-depth: 0 to make sure all branches are fetched as they must be visible to the ECS Deploy Runner
          fetch-depth: 0
      # Invoke the ECS Deploy Runner with the terragrunt plan-all action. The command will be invoked from the path
      # that matches the workflow name (in this example it is test-123456789123/us-east-1/dev), and using the AWS
      # credentials supplied as job environment variables
      - name: plan
        uses: distil/ecs-deploy-runner-github-action@main
        with:
          command: plan-all
  
  # This job performs a terragrunt apply-all
  apply:
    # It will only run after a successful plan job that is described in the previous section
    needs: plan
    # Optional - define the GitHub Environment in which this job is executed. This is useful for things such as setting
    # environment-specific variables such as AWS credentials.
    #
    # It is possible to include an approval step here by configuring GitHub Environment protection rules, and setting
    # the environment to require approval before deployment. At the time of writing this GitHub Environments are a beta
    # feature and do not support only requiring approvals in specific jobs, so to achieve a worflow run where a
    # terragrunt plan runs without requiring approval, while an apply does need to be approved, two separate
    # environments can be set up - e.g. with '-plan' and '-apply' suffixes, and only the '-apply' environment could
    # contain the protection rules (and both environments would have the same secrets defined).
    environment:
      name: test-123456789123
    env:
      # Job specific environment variables - recommended to be populated from the GitHub environment assigned to the job
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    runs-on: ubuntu-latest
    if: github.event_name == 'push'

    steps:
      # Check out the repository
      - name: checkout
        uses: actions/checkout@v2
        with:
          # Use fetch-depth: 0 to make sure all branches are fetched as they must be visible to the ECS Deploy Runner
          fetch-depth: 0
      # Invoke the ECS Deploy Runner with the terragrunt apply-all action. The command will be invoked from the path
      # that matches the workflow name (in this example it is test-123456789123/us-east-1/dev), and using the AWS
      # credentials supplied as job environment variables
      - name: apply
        uses: distil/ecs-deploy-runner-github-action@main
        with:
          command: apply-all
```

## Links

- [How to configure a production-grade CI-CD workflow for infrastructure code](https://gruntwork.io/guides/automations/how-to-configure-a-production-grade-ci-cd-setup-for-apps-and-infrastructure-code/)

## To Do

- Add `docker-image-builder` support.
- Add `ami-builder` support.
