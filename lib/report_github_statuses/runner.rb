# frozen_string_literal: true

require_relative './buildkite'
require_relative './github/client'

require 'yaml'

module ReportGithubStatuses
  class Runner
    class << self
      def run(step_status_config_path: nil)
        step_status_config_path ||= ENV['BUILDKITE_PLUGIN_REPORT_GITHUB_STATUSES_STEP_STATUS_CONFIG_PATH']

        new(YAML.load_file(step_status_config_path)).run
      end
    end

    attr_reader :step_status_config

    def initialize(step_status_config)
      @step_status_config = step_status_config
    end

    def run
      passed_jobs, failed_and_skipped_jobs = all_jobs_for_build.partition do |job|
        job.dig("node", "state") == "SKIPPED" || job.dig("node", "passed")
      end

      passed_labels = passed_jobs.map { |job| label_for_job(job) }
      failed_and_skipped_jobs.reject! { |job| label_for_job(job).in?(passed_labels) }

      skipped_jobs, failed_jobs = failed_and_skipped_jobs.partition do |job|
        job.dig("node", "state") == "BROKEN"
      end

      failed_steps  = failed_jobs.map { |job| label_for_job(job) }
      skipped_steps = skipped_jobs.map { |job| label_for_job(job) }

      report_statuses(failed_steps, skipped_steps)
    end

    private

    def report_statuses(failed_steps, skipped_steps)
      step_status_config["statuses"].each do |context, config|
        failed_steps_for_status  = steps_for_status(failed_steps, config)
        skipped_steps_for_status = steps_for_status(skipped_steps, config)

        if failed_steps_for_status.any?
          report_status(context, 'failure', config.dig("description", "failure").gsub("{{count}}", failed_steps_for_status.count.to_s))
        elsif skipped_steps_for_status.empty?
          report_status(context, 'success', config.dig("description", "success"))
        end
      end
    end

    def report_status(context, state, description)
      github_client.create_status(
        github_repo,
        ENV['BUILDKITE_COMMIT'],
        state,
        context: context,
        description: description,
        target_url:  ENV['BUILDKITE_BUILD_URL']
      )
    end

    def steps_for_status(steps, status)
      steps.select { |step| status["steps"].any? { |pattern| pattern == step || step =~ Regexp.new(pattern) } }
    end

    def label_for_job(job)
      job.dig("node", "label") or raise "Label missing for job #{job.inspect}"
    end

    def all_jobs_for_build
      @all_jobs_for_build ||= ReportGithubStatuses::Buildkite.jobs_for_build(ENV["BUILDKITE_BUILD_ID"])
    end

    # Turns the BUILDKITE_REPO environment variable into the repo slug for github statuses
    # Example: git@github.com:Invoca/repo.git => Invoca/repo
    def github_repo
      ENV['BUILDKITE_REPO'].present? or raise 'BUILDKITE_REPO missing from environment'
      @github_repo ||= ENV['BUILDKITE_REPO'].split(':').last.split('.git').first
    end

    def github_client
      @github_client ||= ReportGithubStatuses::Github::Client.new
    end
  end
end
