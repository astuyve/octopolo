#!/usr/bin/env rake
require "gemfury/tasks"
require "rspec/core/rake_task"
gemspec = Gem::Specification.load Dir["*.gemspec"].first

namespace :release do

  task :release do
    Rake::Task["fury:release"].invoke
    Rake::Task["release:tag"].invoke
  end

  task :tag do
    %x(git tag v#{gemspec.version} && git push --tag)
  end
end

desc "Release v#{gemspec.version} of #{gemspec.name}"
task :release => ["release:release"]

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  RSpec::Core::RakeTask.new(:docs) do |t|
    t.rspec_opts = ["--format doc"]
  end
end

task :default => :spec

# TODO dogfood this rake task and wrap it into a script that is tested and whatnot
desc "Create new automation script"
task :new, [:scriptname] do |t, args|
  require "erb"
  scriptname = args[:scriptname]

  if scriptname.nil? or scriptname.empty?
    puts "Must provide a script name, e.g., rake new[do_something]"
  else
    # turn foo-bar into FooBar
    class_file_name = scriptname.gsub(/[-]/, "_")
    class_name = scriptname.split(/[_-]/).map(&:capitalize).join

    puts "Creating a new script named #{scriptname} with a class named #{class_name}"

    files = {
      "templates/script.erb" => "bin/#{scriptname}",
      "templates/lib.erb" => "lib/automation/scripts/#{class_file_name}.rb",
      "templates/spec.erb" => "spec/automation/scripts/#{class_file_name}_spec.rb",
    }

    files.each do |template_path, output_path|
      base_path = File.dirname(__FILE__)
      template_file = File.expand_path(template_path, base_path)
      output_file = File.expand_path(output_path, base_path)
      perms = output_path.include?("bin/") ? 0755 : 0666

      puts "writing to #{output_path}"
      File.open(output_file, "w+", perms) do |f|
        f.write(ERB.new(File.read(template_file)).result(binding))
      end
    end

  end
end
