# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'octokit'

module ReportGithubStatuses
  module Github
    class Client < Octokit::Client
      def initialize(*args, access_token: nil, **options)
        access_token ||= ENV['GITHUB_TOKEN'].presence or raise 'Github Access Token required.'
        super(*args, **options.merge(access_token: access_token))
      end
    end
  end
end
