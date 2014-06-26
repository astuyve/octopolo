require_relative "../scripts"

module Octopolo
  module Scripts
    class SyncBranch
      include ConfigWrapper
      include CLIWrapper
      include GitWrapper

      attr_accessor :branch

      def self.execute(branch=nil)
        new(branch).execute
      end

      def initialize(branch=nil)
        @branch = branch || default_branch
      end

      # Public: Default value of branch if none given
      def default_branch
        config.deploy_branch
      end

      def execute
        merge_branch
      end

      # Public: Merge the specified remote branch into your local
      def merge_branch
        git.merge branch
      rescue Git::MergeFailed
        cli.say "Merge failed. Please resolve these conflicts."
      end
    end
  end
end
