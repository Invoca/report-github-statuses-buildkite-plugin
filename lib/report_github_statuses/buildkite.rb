# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'net/http'
require 'uri'
require 'json'

module ReportGithubStatuses
  module Buildkite
    GRAPHQL_URI = URI.parse("https://graphql.buildkite.com/v1")

    class << self
      def jobs_for_build(uuid)
        response_json = buildkite_graphql_request(<<~EOS)
          {
            build(uuid: "#{uuid}") {
              id,
              url,
              jobs(type: [COMMAND], first: 500) {
                edges {
                  node {
                    ... on JobTypeCommand {
                      label,
                      passed,
                      state,
                      softFailed
                    }
                  }
                }
              }
            }
          }
        EOS

        response_json.dig("data", "build", "jobs", "edges") or raise "No jobs returned for the build #{uuid}: #{response_json.inspect}"
      end

      private

      def buildkite_graphql_request(query)
        ENV['BUILDKITE_GRAPHQL_ACCESS_TOKEN'].present? or raise "BUILDKITE_GRAPHQL_ACCESS_TOKEN is required to query Buildkite."

        request = Net::HTTP::Post.new(GRAPHQL_URI)
        request['Authorization'] = "Bearer #{ENV['BUILDKITE_GRAPHQL_ACCESS_TOKEN']}"
        request.body = { query: query }.to_json

        response = Net::HTTP.start(GRAPHQL_URI.hostname, GRAPHQL_URI.port, { use_ssl: true }) { |http| http.request(request) }
        JSON.parse(response.body)
      end
    end
  end
end
