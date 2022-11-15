workers(5)
threads(1,1)
bind("tcp://localhost:3210")
environment("development")


before_fork do
  require 'puma_worker_killer'
  PumaWorkerKiller.enable_rolling_restart
  PumaWorkerKiller.config do |config|
    config.ram           = 1024 # mb
    config.frequency     = 5    # seconds
    config.percent_usage = 0.98
    config.rolling_restart_frequency = 10 #* 60 * 60
    config.reaper_status_logs = true

    config.pre_term = -> (worker) { puts "Worker #{worker.inspect} being killed" }
    config.rolling_pre_term = -> (worker) { puts "Worker #{worker.inspect} being killed by rolling restart" }
  end
  PumaWorkerKiller.start
end
