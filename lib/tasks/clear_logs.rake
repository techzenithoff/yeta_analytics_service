#require "time"

#require './lib/shared_utils/utils'

#include SharedUtils::AppLogger

namespace :logs do
	desc "Clear logs"
	task clear_logs: :environment do
		#cron_logger.info("======== BEFORE CRON: unprocessed update football data, at: #{Time.now} ===========")
		Logs::ClearLogsJob.perform_now
		#cron_logger.info("======== AFTER CRON: unprocessed update football data, at: #{Time.now} ===========")
	end
end