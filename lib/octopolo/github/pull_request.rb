require "automation/github"
require "automation/github/commit"
require "automation/github/pull_request_creator"
require "automation/github/user"
require "automation/week"
require "octokit"

module Automation
  module GitHub
    class PullRequest
      attr_accessor :pull_request_data
      attr_accessor :repo_name
      attr_accessor :number

      # used to filter URLs for issues
      ISSUE_URLS = [
        /thedesk\.sportngin\.com/,
        /thedesk\.tstmedia\.com/,
      ]

      def initialize repo_name, number, pull_request_data = nil
        raise MissingParameter if repo_name.nil? or number.nil?

        self.repo_name = repo_name
        self.number = number
        self.pull_request_data = pull_request_data
      end

      # Public: All closed pull requests for a given repo
      #
      # repo_name - Full name ("account/repo") of the repo in question
      #
      # Returns an Array of PullRequest objects
      def self.closed repo_name
        GitHub.pull_requests(repo_name, "closed").map do |data|
          new repo_name, data.number, data
        end
      end

      # Public: Create a pull request for the given repo
      #
      # repo_name - Full name ("account/repo") of the repo in question
      # options - Hash of pull request information
      #   title: Title of the pull request
      #   description: Brief description of the pull request
      #   release: Boolean indicating if the pull request is for Release
      #   destination_branch: Which branch to merge into
      #   source_branch: Which branch to be merged
      #
      # Returns a PullRequest instance
      def self.create repo_name, options
        # create via the API
        creator = PullRequestCreator.perform(repo_name, options)
        # wrap in our class
        new repo_name, creator.number, creator.pull_request_data
      end

      def pull_request_data
        @pull_request_data ||= GitHub.pull_request(repo_name, number)
      rescue Octokit::NotFound
        raise NotFound
      end

      def title
        pull_request_data.title
      end

      def url
        pull_request_data.html_url
      end

      def branch
        pull_request_data.head.ref
      end

      def mergeable?
        pull_request_data.mergeable
      end

      def week
        Week.parse pull_request_data.closed_at
      end

      def commenter_names
        exlude_automation_user (comments.map{ |comment| GitHub::User.new(comment.user.login).author_name }.uniq - author_names)
      end

      def author_names
        exlude_automation_user commits.map(&:author_name).uniq
      end

      def exlude_automation_user(user_list)
        user_list.reject{|u| GitHub.excluded_users.include?(u) }
      end

      def body
        pull_request_data.body || ""
      end

      def external_urls
        # extract http and https URLs from the body
        URI.extract body, %w(http https)
      end

      def issue_urls
        external_urls.select do |url|
          ISSUE_URLS.any? { |regex| url =~ regex }
        end
      end

      def human_app_name
        repo = repo_name.split("/").last
        repo.split("_").map(&:capitalize).join(" ")
      end

      def commits
        @commits ||= Commit.for_pull_request self
      end

      def comments
        @comments ||= GitHub.issue_comments(repo_name, number)
      end

      def bug?
        issue_urls.any? || title =~ /bug/i || title =~ /fix/i
      end

      # NOTE I don't know that I like duplicating some of the logic in PullRequestCreator. Maybe extract to a constant.
      def release?
        title.start_with? "Release: "
      end

      # Public: Add a comment to the pull request
      #
      # message - A String containing the desired comment body
      def write_comment(message)
        GitHub.add_comment repo_name, number, ":octocat: #{message}"
      rescue Octokit::UnprocessableEntity => error
        raise CommentFailed, "Unable to write the comment: '#{error.message}'"
      end

      MissingParameter = Class.new StandardError
      NotFound = Class.new StandardError
      CommentFailed = Class.new StandardError
    end
  end
end
