# frozen_string_literal: true

require_relative '../../../lib/report_github_statuses/github/client'

RSpec.describe ReportGithubStatuses::Github::Client do
  subject { described_class.new }

  context 'when GITHUB_TOKEN is missing from the environment' do
    it 'raises an error' do
      expect { subject }.to raise_error(/Github Access Token required./)
    end
  end
end
