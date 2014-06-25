require_relative "../git"
require_relative "../scripts"

desc "View and delete stale branches"
command 'stale-branches' do |c|
  c.desc "Delete the stale branches (default: false)"
  c.switch [:D, :delete], :negatable => false

  c.action do |global_options, options, args|
    options = global_options.merge(options)
    Octopolo::Scripts::AcceptPull.execute options[:delete]
  end
end


module Octopolo
  module Scripts
    class StaleBranches
      include CLIWrapper
      include ConfigWrapper
      include GitWrapper

      attr_accessor :delete

      DEFAULT_BRANCHES = %W(HEAD master staging production)

      #option "--delete", :flag, "Delete the stale branches (default: false)"

      def initialize(delete=false)
        @delete = delete
      end

      def execute
        if delete?
          delete_stale_branches
        else
          display_stale_branches
        end
      end

      def delete?
        delete
      end

      # Private: Display the stale branches in the project
      def display_stale_branches
        stale_branches.each do |branch_name|
          cli.say "* #{branch_name}"
        end
      end
      private :display_stale_branches

      # Private: Delete the stale branches in the project
      def delete_stale_branches
        stale_branches.each do |branch_name|
          git.delete_branch(branch_name)
        end
      end
      private :delete_stale_branches

      # Private: The list of stale branches for the project
      #
      # Returns an Array of Strings
      def stale_branches
        git.stale_branches(config.deploy_branch, config.branches_to_keep)
      end
      private :stale_branches
    end
  end
end

