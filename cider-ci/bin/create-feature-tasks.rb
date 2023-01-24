#!/usr/bin/env ruby
require 'yaml'
require 'pry'

STRICT_MODE = true

def task_hash(name, exec)
  h = { 'name' => name,
        'scripts' => {
          'test' => {
            'body' => "#!/usr/bin/env bash\nset -euo pipefail\nmkdir -p log\n#{exec}"
          }
        }
      }
  h
end

def task_for_feature_file file_path, _timeout = 200
  name= file_path.match(/features\/(.*)\.feature/).captures.first
  exec = %{xvfb-run -a -e log/xvfb.log ./bin/cucumber -p default #{STRICT_MODE ? "--strict " : nil}"#{file_path}"}
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
filepath = 'cider-ci/tasks/all-features.yml'
create_feature_tasks(filepath, leihs_feature_files)
