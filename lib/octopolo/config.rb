require "date" # necessary to get the Date.today convenience method
require "yaml"
require "automation/engine_yard_api"
require "automation/user_config"

module Automation
  class Config
    FILE_NAME = ".automation.yml"
    INFRASTRUCTURE_KEY = File.expand_path(File.join("~", ".ssh", "ey_infrastructure"))
    DEVELOPMENT_KEY = File.expand_path(File.join("~", ".ssh", "ey_development"))

    RECENT_TAG_LIMIT = 9
    # we use date-based tags, so look for anything starting with a 4-digit year
    RECENT_TAG_FILTER = /^\d{4}.*/

    attr_accessor :cli
    # customizable bits
    attr_accessor :branches_to_keep
    attr_accessor :cloud_ngin_app_name
    attr_accessor :deploy_branch
    attr_accessor :deploy_environments
    attr_accessor :deploy_methods
    attr_accessor :engine_yard_app_name
    attr_accessor :github_repo

    def initialize(attributes={})
      self.cli = Automation::CLI

      attributes.each do |key, value|
        self.send("#{key}=", value)
      end
    end

    # default values for these customizations
    def deploy_branch
      @deploy_branch || "master"
    end

    def branches_to_keep
      @branches_to_keep || []
    end

    def deploy_environments
      @deploy_environments || []
    end

    def deploy_methods
      @deploy_methods || []
    end

    def github_repo
      @github_repo || raise(MissingRequiredAttribute)
    end
    # end defaults

    def self.parse
      new(attributes_from_file)
    end

    def self.attributes_from_file
      YAML.load_file(automation_config_path)
    end

    def self.automation_config_path
      if File.exists?(FILE_NAME)
        File.join(Dir.pwd, FILE_NAME)
      else
        old_dir = Dir.pwd
        Dir.chdir('..')
        if old_dir != Dir.pwd
          automation_config_path
        else
          Automation::CLI.say "Could not find #{FILE_NAME}"
          exit
        end
      end
    end

    def basedir
      File.basename File.dirname Config.automation_config_path
    end

    def current_app?(app_name)
      engine_yard_app_name == app_name.to_s
    end

    def remote_branch_exists?(branch)
      branches = Automation::CLI.perform "git branch -r", false
      branch_list = branches.split(/\r?\n/)
      branch_list.each { |x| x.gsub!(/\*|\s/,'') }
      branch_list.include? "origin/#{branch}"
    end

    def api_object
      EngineYardAPI.fetch
    end

    def reload_cached_api_object
      EngineYardAPI.reload_cached_api_object
    end

    def servers
      result = {}

      api_object.apps.each do |app|
        result[app.name] = {}
        app.environments.each do |environment|
          result[app.name][environment.name] = {}
          environment.instances.each do |instance|
            value = {
              "amazon_id" => instance.amazon_id,
              "hostname" => instance.hostname,
              "name" => instance.name,
              "role" => instance.role,
              "allow_non_infrastructure" => (not environment.name.include?("production"))
            }
            result[app.name][environment.name][instance_key(instance)] = value
          end
        end
      end

      result
    end

    def instance_key(instance)
      "#{instance.role} #{instance.name} #{instance.hostname} #{instance.amazon_id}"
    end

    def infrastructure?
      File.exist?(INFRASTRUCTURE_KEY)
    end

    def app_name
      # if not a Cloud Ngin app, won't have that instantiated
      cloud_ngin_app_name || engine_yard_app_name || basedir
    end

    # To be used when attempting to call a Config attribute for which there is
    # no sensible default and one hasn't been supplied by the app
    MissingRequiredAttribute = Class.new(StandardError)
    # To be used when looking for a branch of a given type (like staging or
    # deployable), but none exist.
    NoBranchOfType = Class.new(StandardError)
  end
end
