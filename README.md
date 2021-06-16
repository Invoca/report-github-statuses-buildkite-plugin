# report-github-statuses-buildkite-plugin
A Buildkite plugin for reporting statuses to github at the end of a build based on the result of the steps in the build.

## Usage

```yaml
steps:
# ...
- step: Report statuses
  plugins:
  - adabay/vault-key-value#v0.9.5:
      secrets:
      - secret_path: secret/kubernetes/buildkite/buildkite
        secret_key: graphql_token
        exported_env_variable_name: BUILDKITE_GRAPHQL_ACCESS_TOKEN
  - invoca/report-github-statuses#main:
      step_status_config_path: .buildkite/step_status_config.yml
```

## Example Step Status Configuration

```yaml
---
statuses:
  gems-merged-to-mainline:
    description:
      success: All gems are running off master shas!
      failure: Gems are currently running off feature branches, this is dangerous.
    steps:
    - ":white_check_mark: Gems Merged to Mainline"
  production-assets-pushed:
    description:
      success: Production assets pushed!
      failure: Failed to push production assets to s3
    steps:
    - ":rails: Rails 4 Production Asset Push"
  production-image-ready:
    description:
      success: Production docker image pushed to DockerHub
      failure: Failed to push docker image to DockerHub
    steps:
    - ":docker: Rails 4 Web App"
  clean-build:
    description:
      success: All unit tests passed!
      failure: Unit tests failed on {{count}} steps
    steps:
    - ":jest: Client Tests"
    - ":database: Migrations Check"
    - ":white_check_mark: Test Coverage"
    - ":rails::rspec: .*"
    - ":rails::chrome: .*"
    - ":rails::recycle: .*"
    - ":rails::rspec::recycle: .*"
    - ":rails::chrome::recycle: .*"
  clean-autobahn:
    description:
      success: All e2e tests passed!
      failure: E2E tests failed on {{count}} steps
    steps:
    - ":oncoming_automobile: E2E .*"
```
