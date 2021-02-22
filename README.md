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
name: test-123456789123/us-east-1/dev
on:
  push:
    branches:
      - main
    paths:
      - 'test-123456789123/us-east-1/dev/**'

  pull_request:
    paths:
      - 'test-123456789123/us-east-1/dev/**'

env:
  AWS_ACCOUNT_ID: "123456789123"
  AWS_REGION: "us-east-1"

jobs:

  plan:
    environment:
      name: test-123456789123
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      GITHUB_OAUTH_TOKEN: ${{ secrets.GRUNTWORK_OAUTH_TOKEN }}
    runs-on: ubuntu-latest

    steps:
      - name: checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - name: plan
        uses: distil/ecs-deploy-runner-github-action@main
        with:
          command: plan-all

  apply:
    needs: plan
    environment:
      name: test-123456789123
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      GITHUB_OAUTH_TOKEN: ${{ secrets.GRUNTWORK_OAUTH_TOKEN }}
    runs-on: ubuntu-latest
    if: github.event_name == 'push'

    steps:
      - name: checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0
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
