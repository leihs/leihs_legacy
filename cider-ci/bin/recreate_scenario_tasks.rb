#!/usr/bin/env ruby
require 'yaml'
require 'pry'

DEFAULT_BROWSER = \
  ENV['DEFAULT_BROWSER'] ? ENV['DEFAULT_BROWSER'] : :firefox
CI_SCENARIOS_PER_TASK = Integer(ENV['CI_SCENARIOS_PER_TASK'] || 1)
STRICT_MODE = true
ENGINES = ['leihs_admin',
           'procurement']
EXCLUDE_TAGS = %w(@upcoming
                  @generating_personas
                  @manual
                  @broken
                  @v4stable
                  @flapping
                  @unstable)

def task_hash(name, exec)
  h = { 'name' => name,
        'scripts' => {
          'test' => {
            'body' => "set -eux\nexport PATH=~/.rubies/$RUBY/bin:$PATH\nmkdir -p log\n#{exec}"
          }
        }
      }
  h
end

def create_scenario_tasks(filepath,
                          feature_dir_paths,
                          framework: nil,
                          additional_options: nil,
                          tags: nil)
  File.open(filepath,'w') do |f|
    h1 = {}

    egrep_cmd = \
      "egrep -R -n -B 1 -H '^\s*(Scenario|Szenario)' #{feature_dir_paths.join(' ')}"

    `#{egrep_cmd}`
      .split("--\n")
      .map { |x| x.split("\n") }
      .each do |t, s|

      if tags and not t.match /#{tags.join("|")}/
        next
      end

      if not tags and t.match /#{EXCLUDE_TAGS.join("|")}/
        next
      end

      splitted_string = \
        s.split(/:\s*(Scenario|Szenario)( Outline| Template|grundriss)?: /)
      k, v = splitted_string.first.split(':')
      h1[k] ||= []
      h1[k] << v
    end

    h2 = []
    h1.map do |k,v|
      v.each_slice(CI_SCENARIOS_PER_TASK) do |lines|
        path = ([k] + lines).join(':')
        xvfb = "xvfb-run -a -e log/xvfb.log --server-args='-screen 0 1920x1080x24'"
        case framework
        when :cucumber
          exec = "#{xvfb} bundle exec cucumber -p default #{STRICT_MODE ? "--strict " : nil}%s DEFAULT_BROWSER=%s" % [path, DEFAULT_BROWSER]
        when :rspec
          exec = [xvfb, 'bundle exec rspec', additional_options, path].compact.join(' ')
        else
          raise 'Undefined testing framework'
        end

        h2 << task_hash(path, exec)
      end
    end

    h3 = {'tasks' => h2}

    f.write h3.to_yaml
  end
end

############################## MANAGE ###################################

manage_feature_dir_paths = ['features/{login,manage,technical}']

filepath = 'cider-ci/tasks/manage_scenarios.yml'
create_scenario_tasks(filepath, manage_feature_dir_paths, framework: :cucumber)

%w(flapping broken unstable).each do |kind|
  filepath = "cider-ci/tasks/manage_#{kind}_scenarios.yml"
  create_scenario_tasks(filepath, manage_feature_dir_paths, framework: :cucumber, tags: ["@#{kind}"])
end

############################## BORROW ###################################

borrow_feature_dir_paths = ['features/borrow']

filepath = 'cider-ci/tasks/borrow_scenarios.yml'
create_scenario_tasks(filepath, borrow_feature_dir_paths, framework: :cucumber)

%w(flapping broken unstable).each do |kind|
  filepath = "cider-ci/tasks/borrow_#{kind}_scenarios.yml"
  create_scenario_tasks(filepath, borrow_feature_dir_paths, framework: :cucumber, tags: ["@#{kind}"])
end

############################## ENGINES ##################################

ENGINES.each do |engine|
  engine_feature_dir_paths = ["engines/#{engine}/spec/features"]

  filepath = "cider-ci/tasks/#{engine}_scenarios.yml"
  create_scenario_tasks(filepath,
                        engine_feature_dir_paths,
                        framework: :rspec,
                        additional_options: "-r ./engines/#{engine}/spec/load.rb")

  filepath = "cider-ci/tasks/#{engine}_flapping_scenarios.yml"
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
