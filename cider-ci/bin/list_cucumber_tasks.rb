#!/usr/bin/env ruby
require 'yaml'
require 'pry'

DEFAULT_BROWSER = ENV['DEFAULT_BROWSER'] ? ENV['DEFAULT_BROWSER'] : :firefox # [:firefox, :chrome].sample
CI_SCENARIOS_PER_TASK = Integer(ENV['CI_SCENARIOS_PER_TASK'] || 1)
STRICT_MODE = true
ENGINES = ['leihs_admin', 'procurement']

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

def task_for_feature_file file_path, _timeout = 200
  name= file_path.match(/features\/(.*)\.feature/).captures.first
  exec = %{DISPLAY=\":$XVNC_PORT\" bundle exec cucumber -p default #{STRICT_MODE ? "--strict " : nil}"#{file_path}"}
  task_hash(name, exec)
end

def create_feature_tasks(filepath, feature_files)
  File.open(filepath,'w') do |f|
    string = {'tasks' => feature_files.map do |f|
      task_for_feature_file(f)
    end}
    f.write(string.to_yaml)
  end
end

leihs_feature_files = \
  Dir.glob('features/**/*.feature') -
  Dir.glob('features/personas/*.feature') -
  Dir.glob('features/**/*.feature.disabled') -
  Dir.glob('engines/**/features/*')
filepath = 'cider-ci/tasks/all_features.yml'
create_feature_tasks(filepath, leihs_feature_files)

ENGINES.each do |engine|
  engine_feature_files = Dir.glob("engines/#{engine}/features/**/*.feature")
  filepath = "cider-ci/tasks/#{engine}_features.yml"
  create_feature_tasks(filepath, engine_feature_files)
end

EXCLUDE_TAGS = %w(@upcoming @generating_personas @manual @broken @v4stable @flapping @unstable)

def create_scenario_tasks(filepath, feature_files_paths,
                          framework: nil, additional_options: nil, tags: nil, exclude_dir: nil)
  File.open(filepath,'w') do |f|
    h1 = {}

    exclude_dir_option = "--exclude-dir #{exclude_dir}" if exclude_dir
    `egrep -R -n -B 1 -H #{exclude_dir_option} "^\s*(Scenario|Szenario)" #{feature_files_paths.join(' ')}`
      .split("--\n")
      .map{|x| x.split("\n")}
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
    end.compact.sort.to_h

    h2 = []
    h1.map do |k,v|
      require = k =~ /^engines/ ? "-r engines/**/features" : nil
      v.each_slice(CI_SCENARIOS_PER_TASK) do |lines|
        path = ([k] + lines).join(':')
        xvfb = "xvfb-run -a -e log/xvfb.log --server-args='-screen 0 1920x1080x24'"
        case framework
        when :cucumber
          exec = "#{xvfb} bundle exec cucumber -p default %s #{STRICT_MODE ? "--strict " : nil}%s DEFAULT_BROWSER=%s" % [require, path, DEFAULT_BROWSER]
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

manage_feature_files_paths = ['features/{login,manage,technical}/*']

filepath = 'cider-ci/tasks/manage_scenarios.yml'
create_scenario_tasks(filepath, manage_feature_files_paths, framework: :cucumber, exclude_dir: 'borrow')

%w(flapping broken unstable).each do |kind|
  filepath = "cider-ci/tasks/manage_#{kind}_scenarios.yml"
  create_scenario_tasks(filepath, manage_feature_files_paths, framework: :cucumber, tags: ["@#{kind}"])
end

############################## BORROW ###################################

borrow_feature_files_paths = ['features/borrow/*']

filepath = 'cider-ci/tasks/borrow_scenarios.yml'
create_scenario_tasks(filepath, borrow_feature_files_paths, framework: :cucumber)

%w(flapping broken unstable).each do |kind|
  filepath = "cider-ci/tasks/borrow_#{kind}_scenarios.yml"
  create_scenario_tasks(filepath, borrow_feature_files_paths, framework: :cucumber, tags: ["@#{kind}"])
end

############################## ENGINES ##################################

ENGINES.each do |engine|
  filepath = "cider-ci/tasks/#{engine}_scenarios.yml"
  if engine == 'procurement'
    engine_feature_files_paths = ["engines/#{engine}/spec/features/*.feature"]
    create_scenario_tasks(filepath, engine_feature_files_paths, framework: :rspec)

    filepath = "cider-ci/tasks/#{engine}_flapping_scenarios.yml"
    create_scenario_tasks(filepath, engine_feature_files_paths, framework: :rspec, tags: ['@flapping'])
  else # leihs_admin
    engine_feature_files_paths = ["engines/#{engine}/spec/features/*.feature"]
    filepath = "cider-ci/tasks/#{engine}_scenarios.yml"
    create_scenario_tasks(filepath, engine_feature_files_paths,
                          framework: :rspec, additional_options: "-r ./engines/#{engine}/spec/load.rb")
  end
end
