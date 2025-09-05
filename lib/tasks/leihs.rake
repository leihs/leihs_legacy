# -*- encoding : utf-8 -*-
require 'net/http'
require 'json'

namespace :leihs do

  desc 'Build the Leihs RDOC HTML Files'
  task :doc do
    `rake doc:app title="Leihs Application Documentation"`
  end

  desc 'set the deploy information as footer'
  task :set_deploy_information_footer do |branch|
    branch = ENV['BRANCH']
    url = URI.parse("https://api.github.com/repos/leihs/leihs/commits/#{branch}")
    request = Net::HTTP::Get.new(url.path)

    response = \
      Net::HTTP.start(url.host,
                      use_ssl: true,
                      verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
        http.request(request)
      end
    json = JSON.parse response.body
    author = json['commit']['author']
    # NOTE: disabling because of failing deploy
    time_of_commit = DateTime.parse(author['date']).to_s
    time_now = Time.now.to_s
    sha = json['sha']

    # new#
    git_info = {
      branch: branch,
      time_of_deploy: time_now,
      time_of_commit: time_of_commit,
      author: author['name'],
      sha: sha
    }
    File.open('log/git.json', 'w') do |f|
      f.write(git_info.to_json)
    end
    # end new#

    # old#
    File.open(Rails.root.join('app',
                              'views',
                              'staging',
                              '_deploy_information.html.haml'), 'a+') do |f|

      f.puts "\n        %span"
      f.print "          = _(\"this is the branch '%s'\")"
      f.print " % \"#{branch}\""

      f.puts "\n        %span"
      f.print "          = _(\"deployed %s ago\")"
      f.print " % distance_of_time_in_words_to_now(\"#{time_now}\")"

      f.puts "\n        %span\n"
      f.print "          = _(\"last change by '%s'\")"
      f.print " % \"#{author['name']}\"\n"

      f.print "          = _(\"is %s ago\")"
      f.print " % distance_of_time_in_words_to_now(\"#{time_of_commit}\")"
      f.puts "\n        %span\n"
      f.print "          = \"#{sha}\""
    end
    text = File.read(Rails.root.join('app',
                                     'views',
                                     'staging',
                                     '_deploy_information.html.haml'))
    File.open(Rails.root.join('app',
                              'views',
                              'layouts',
                              'splash.html.haml'), 'a+') { |f| f.puts text }
    File.open(Rails.root.join('app',
                              'views',
                              'layouts',
                              'manage.html.haml'), 'a+') { |f| f.puts text }
    File.open(Rails.root.join('app',
                              'views',
                              'layouts',
                              'borrow.html.haml'), 'a+') { |f| f.puts text }
    # end old#
  end

  desc 'Initialize'
  task init: :environment do
    params = { all: ENV['items'] }
    create_some(params)
  end

  desc 'Maintenance'
  task maintenance: :environment do

    # nothing to do

    puts 'Maintenance complete ------------------------'
  end

  desc 'Remind and suspend users'
  task remind_and_suspend: :environment do
    puts "Delivery config: Mails will #{'NOT ' unless SmtpSetting.first.enabled}be sent!"
    puts 'Reminding and suspending users...'
    User.remind_and_suspend_all
    puts 'Remind and suspend complete -----------------------------'
  end

  desc 'Deadline soon reminder'
  task deadline_soon_reminder: :environment do
    puts "Delivery config: Mails will #{'NOT ' unless SmtpSetting.first.enabled}be sent!"
    puts 'Sending a deadline soon reminder...'
    User.send_deadline_soon_reminder_to_everybody
    puts 'Deadline soon reminded ----------------------'
  end

  desc 'Cron: Remind & Maintenance'
  task cron: [:remind_and_suspend, :maintenance, :deadline_soon_reminder]

  desc 'Recreate DB and reindex'
  task reset: :environment  do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:seed'].invoke
  end

  ##############################################################################
  # Refactoring from Backend::TemporaryController

  def create_some(params = {})
    puts "Initializing #{params[:all]} items ..."

    params[:id] = 3
    params[:name] = 'model'
    max = params[:all].to_i
    if max > 0
      Importer.new.start(max)
    else
      Importer.new.start
    end

    create_some_root_categories

    puts 'Complete'
  end

  ###############################################################################

  def create_some_root_categories
    video = Category.find_or_create_by(name: 'Video')
    audio = Category.find_or_create_by(name: 'Audio')
    computer = Category.find_or_create_by(name: 'Computer')
    light = Category.find_or_create_by(name: 'Licht')
    foto = Category.find_or_create_by(name: 'Foto')
    other = Category.find_or_create_by(name: 'Anderes')
    stative = Category.find_or_create_by(name: 'Stative')

    add_to(video, Category.find_or_create_by(name: 'Video Kamera'))
    add_to(video,  Category.find_or_create_by(name: 'Film Kamera'))
    add_to(video,  Category.find_or_create_by(name: 'Video Kamera Zubehör'))
    add_to(video,  Category.find_or_create_by(name: 'Film Kamera Zubehör'))
    add_to(video,  Category.find_or_create_by(name: 'Video Monitor'))
    add_to(video,  Category.find_or_create_by(name: 'Video Recorder/Player'))
    add_to(video,  Category.find_or_create_by(name: 'Stativ Video/Film/Foto'))

    add_to(audio,  Category.find_or_create_by(name: 'Audio Recorder portable'))
    add_to(audio,  Category.find_or_create_by(name: 'Audio Recorder/Player'))
    add_to(audio,  Category.find_or_create_by(name: 'Kopfhörer'))
    add_to(audio,  Category.find_or_create_by(name: 'Lautsprecher/-anlagen'))
    add_to(audio,  Category.find_or_create_by(name: 'Mikrofon'))
    add_to(audio,  Category.find_or_create_by(name: 'Mikrofon Zubehör'))
    add_to(audio,  Category.find_or_create_by(name: 'Verschiedene AV Geräte'))
    add_to(audio,  Category.find_or_create_by(name: 'Verstärker'))
    add_to(audio,  Category.find_or_create_by(name: 'Mikrofon Zubehör'))

    add_to(foto,  Category.find_or_create_by(name: 'Dia-/Hellraumprojektor'))
    add_to(foto,  Category.find_or_create_by(name: 'Foto analog'))
    add_to(foto,  Category.find_or_create_by(name: 'Foto digital'))
    add_to(foto,  Category.find_or_create_by(name: 'Foto Zubehör'))
    add_to(foto,  Category.find_or_create_by(name: 'Stativ Video/Film/Foto'))

    add_to(light,  Category.find_or_create_by(name: 'Licht/Scheinwerfer'))
    add_to(light,  Category.find_or_create_by(name: 'Licht Stative'))
    add_to(light,  Category.find_or_create_by(name: 'Licht Zubehör'))
    add_to(light,  Category.find_or_create_by(name: 'Elektro Material'))

    add_to(computer,  Category.find_or_create_by(name: 'Desktop Macintosh'))
    add_to(computer,  Category.find_or_create_by(name: 'Desktop PC'))
    add_to(computer,  Category.find_or_create_by(name: 'Externer Massenspeicher'))
    add_to(computer,  Category.find_or_create_by(name: 'IT-Display'))
    add_to(computer,  Category.find_or_create_by(name: 'IT-Zubehör'))
    add_to(computer,  Category.find_or_create_by(name: 'Notebook'))
    add_to(computer,  Category.find_or_create_by(name: 'PowerBook'))
    add_to(computer,  Category.find_or_create_by(name: 'Scanner/Lesegerät'))
    add_to(computer,  Category.find_or_create_by(name: 'Server'))
    add_to(computer,  Category.find_or_create_by(name: 'Netzwerkkomponente'))
    add_to(computer,  Category.find_or_create_by(name: 'Andere Hardware'))

    add_to(other, Category.find_or_create_by(name: 'DVD - Recorder/Player'))
    add_to(other, Category.find_or_create_by(name: 'Medien-Rack/-Wagen'))
    add_to(other, Category.find_or_create_by(name: 'Andere Hardware'))
    add_to(other, Category.find_or_create_by(name: 'Leinwand'))
    add_to(other, Category.find_or_create_by(name: 'Set-/Bühnenbau'))

    add_to(stative, Category.find_or_create_by(name: 'Licht Stative'))
    add_to(stative, Category.find_or_create_by(name: 'Stativ Video/Film/Foto'))
  end

  def add_to(parent, sub)
    sub.set_parent_with_label(parent, sub.name)
  end

end
