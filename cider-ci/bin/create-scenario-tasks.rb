#!/usr/bin/env ruby
require 'yaml'

STRICT_MODE = true
ENGINES = ['leihs_admin',
           'procurement']
EXCLUDE_TAGS = %w(@upcoming
                  @manual
                  @broken
                  @v4stable
                  @flapping
                  @unstable)

def task_hash(name, exec)
  { 'name' => name,
        'scripts' => {
          'test' => {
            'body' => "set -eux\nexport PATH=~/.rubies/$RUBY/bin:$PATH\nmkdir -p log\n#{exec}"
      }
    }
  }
end

def create_scenario_tasks(filepath,
                          feature_dir_paths,
                          framework: nil,
                          additional_options: nil,
                          tags: nil)
  File.open(filepath,'w') do |f|
    tasks = []

    egrep_cmd = \
      "egrep -R -n -B 1 -H '^\s*(Scenario|Szenario)' #{feature_dir_paths.join(' ')}"

    `#{egrep_cmd}`
      .split("--\n")
      .map { |x| x.split("\n") }
      .sort { |a, b| a.first <=> b.first }
      .each do |t, s|

      if tags and not t.match /#{tags.join("|")}/
        next
      end

      if not tags and t.match /#{EXCLUDE_TAGS.join("|")}/
        next
      end

      path = get_path(s)
      exec = get_exec_command(path, framework, additional_options)
      task_extensions = get_task_extensions(t)
      tasks << task_hash(path, exec).merge(task_extensions)
    end

    result = {'tasks' => tasks}
    f.write result.to_yaml
  end
end

def get_task_extensions(t)
  task_hash_extension = {}
  if m = t.match(/@eager_trials_(\d+)/)
    task_hash_extension['eager_trials'] = m[1].to_i
  end
  task_hash_extension
end

def get_path(s)
  splitted_string = \
    s.split(/:\s*(Scenario|Szenario)( Outline| Template|grundriss)?: /)
  k, v = splitted_string.first.split(':')
  "#{k}:#{v}"
end

def get_exec_command(path, framework, additional_options)
  xvfb = "xvfb-run -a -e log/xvfb.log --server-args='-screen 0 1920x1080x24'"

  case framework
  when :cucumber
    exec = "#{xvfb} bundle exec cucumber #{STRICT_MODE ? "--strict " : nil}#{path}"
  when :rspec
    exec = [xvfb, 'bundle exec rspec', additional_options, path].compact.join(' ')
  else
    raise 'Undefined testing framework'
  end
end

############################## MANAGE ###################################

manage_feature_dir_paths = ['features/login', 'features/manage', 'features/technical']

filepath = 'cider-ci/tasks/manage-scenarios.yml'
create_scenario_tasks(filepath, manage_feature_dir_paths, framework: :cucumber)

%w(flapping broken unstable).each do |kind|
  filepath = "cider-ci/tasks/manage-#{kind}-scenarios.yml"
  create_scenario_tasks(filepath, manage_feature_dir_paths, framework: :cucumber, tags: ["@#{kind}"])
end


filepath = "cider-ci/tasks/manage-rspec-scenarios.yml"
create_scenario_tasks(filepath,
                      ['spec/features/manage'],
                      framework: :rspec,
                      additional_options: "-r ./spec/steps/manage/load.rb")

filepath = "cider-ci/tasks/manage-rspec-flapping-scenarios.yml"
create_scenario_tasks(filepath,
                      ['spec/features/manage'],
                      framework: :rspec,
                      additional_options: "-r ./spec/steps/manage/load.rb",
                      tags: ['@flapping'])

############################## BORROW ###################################

borrow_feature_dir_paths = ['features/borrow']

filepath = 'cider-ci/tasks/borrow-scenarios.yml'
create_scenario_tasks(filepath, borrow_feature_dir_paths, framework: :cucumber)

%w(flapping broken unstable).each do |kind|
  filepath = "cider-ci/tasks/borrow-#{kind}-scenarios.yml"
  create_scenario_tasks(filepath, borrow_feature_dir_paths, framework: :cucumber, tags: ["@#{kind}"])
end

filepath = "cider-ci/tasks/borrow-rspec-scenarios.yml"
create_scenario_tasks(filepath,
                      ['spec/features/borrow'],
                      framework: :rspec,
                      additional_options: "-r ./spec/steps/borrow/load.rb")

filepath = "cider-ci/tasks/borrow-rspec-flapping-scenarios.yml"
create_scenario_tasks(filepath,
                      ['spec/features/borrow'],
                      framework: :rspec,
                      additional_options: "-r ./spec/steps/borrow/load.rb",
                      tags: ['@flapping'])

############################## ENGINES ##################################

ENGINES.each do |engine|
  engine_feature_dir_paths = ["engines/#{engine}/spec/features"]

  filepath = "cider-ci/tasks/#{engine}-scenarios.yml"
  create_scenario_tasks(filepath,
                        engine_feature_dir_paths,
                        framework: :rspec,
                        additional_options: "-r ./engines/#{engine}/spec/load.rb")

  filepath = "cider-ci/tasks/#{engine}-flapping-scenarios.yml"
  create_scenario_tasks(filepath,
                        engine_feature_dir_paths,
                        framework: :rspec,
                        additional_options: "-r ./engines/#{engine}/spec/load.rb",
                        tags: ['@flapping'])
end

############################## HOTSPOTS #################################

feature_dir_paths = ['features']
filepath = 'cider-ci/tasks/hotspots.yml'
create_scenario_tasks(filepath, feature_dir_paths, framework: :cucumber, tags: ['@hotspot'])
