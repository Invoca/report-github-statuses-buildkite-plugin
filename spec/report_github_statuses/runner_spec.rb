# frozen_string_literal: true

require 'climate_control'
require_relative '../../lib/report_github_statuses/runner'

RSpec.describe ReportGithubStatuses::Runner do
  describe '.run' do
    let(:step_status_config) do
      {
        'statuses' => {
          'context-1' => {
            'description' => {
              'success' => 'success',
              'failure' => 'failure'
            },
            'steps' => ['Hello World passed']
          },
          'context-2' => {
            'description' => {
              'success' => 'success',
              'failure' => 'failure'
            },
            'steps' => ['Hello World failed']
          }
        }
      }
    end

    let(:jobs_for_build_response) do
      [
        {
          'node' => {
            'label'  => 'Hello World passed',
            'state'  => 'COMPLETED',
            'passed' => true
          }
        },
        {
          'node' => {
            'label'  => 'Hello World failed',
            'state'  => 'FAILED',
            'passed' => false
          }
        }
      ]
    end

    let(:uuid)          { '123-123-123213' }
    let(:runner)        { described_class.new(step_status_config) }
    let(:github_client) { double(ReportGithubStatuses::Github::Client) }

    before do
      expect(ReportGithubStatuses::Buildkite).to receive(:jobs_for_build).with(uuid).and_return(jobs_for_build_response)
      allow(runner).to receive(:github_client).and_return(github_client)
    end

    it 'reports statuses to github' do
      expect(github_client).to receive(:create_status).with(
        'Invoca/repo',
        '233213123131',
        'success',
        context: 'context-1',
        description: 'success',
        target_url: 'https://buildkite.com/invoca/repo/1'
      )

      expect(github_client).to receive(:create_status).with(
        'Invoca/repo',
        '233213123131',
        'failure',
        context: 'context-2',
        description: 'failure',
        target_url: 'https://buildkite.com/invoca/repo/1'
      )

      ClimateControl.modify(
        BUILDKITE_BUILD_ID:  uuid,
        BUILDKITE_COMMIT:    '233213123131',
        BUILDKITE_BUILD_URL: 'https://buildkite.com/invoca/repo/1',
        BUILDKITE_REPO:      'git@github.com:Invoca/repo.git'
      ) do
        runner.run
      end
    end
  end
end
