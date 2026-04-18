# Threads
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count)
threads min_threads_count, max_threads_count

# Environment
environment ENV.fetch("RAILS_ENV", "development")

# Bind (IMPORTANT pour Docker + Traefik)
bind "tcp://0.0.0.0:3000"

# Timeout (dev uniquement)
if ENV.fetch("RAILS_ENV", "development") == "development"
  worker_timeout 3600
end

# Workers (important pour staging/prod)
workers ENV.fetch("WEB_CONCURRENCY", 1)

# Optimisation mémoire
preload_app!

# PID file
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Restart
plugin :tmp_restart