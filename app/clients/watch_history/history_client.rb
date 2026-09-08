# app/clients/watch_history/history_client.rb
# frozen_string_literal: true

module WatchHistory
  class HistoryClient < BaseClient
    def self.base_url
      ENV.fetch('WATCH_HISTORY_SERVICE_INTERNAL_URL', 'http://localhost:3007')
    end

    def self.audience_name
      "watch-history-service"
    end

    # Récupère l'historique avec filtres (utilise l'action filter)
    def self.list(filters = {})
      puts "📤 [HistoryClient] Fetching watch histories with filters: #{filters}"
      path = "/internal/api/v1/watch-histories/filter"

      # ✅ Sanitize récursivement clés ET valeurs (Symbol -> String, Date/Time -> iso8601)
      sanitized_filters = deep_sanitize(filters)
      body = { filters: sanitized_filters }

      response = request(:post, path, body: body)

      puts "✅ [HistoryClient] Response: #{response.inspect}"
      return [] if response.blank? || response[:error]
      response || []
    rescue StandardError => e
      Rails.logger.error "[HistoryClient] Failed to fetch watch histories: #{e.message}"
      Rails.logger.error e.backtrace.first(15).join("\n")
      puts "❌ [HistoryClient] Error: #{e.message}"
      puts e.backtrace.first(15)
      []
    end

    # Récupère par compte IDs
    def self.list_by_account_ids(account_ids, filters = {})
      return [] if account_ids.blank?

      # account_ids peut être un array ou un single ID
      account_id = account_ids.is_a?(Array) ? account_ids.first : account_ids
      account_id = account_id.to_i  # ✅ Convertir en Integer

      all_filters = filters.merge(account_id: account_id)
      list(all_filters)
    end

    # Récupère par période
    def self.list_by_period(date_from, date_to, filters = {})
      all_filters = filters.dup
      all_filters[:date_from] = format_date(date_from) if date_from.present?
      all_filters[:date_to]   = format_date(date_to) if date_to.present?

      list(all_filters)
    end

    # Récupère par type de contenu
    def self.list_by_type(content_type, filters = {})
      return [] if content_type.blank?

      all_filters = filters.merge(watchable_type: content_type.to_s)
      list(all_filters)
    end

    # Récupère par période ET type
    def self.list_by_period_and_type(date_from, date_to, content_type = nil, filters = {})
      all_filters = filters.dup
      all_filters[:date_from] = format_date(date_from) if date_from.present?
      all_filters[:date_to]   = format_date(date_to) if date_to.present?
      all_filters[:watchable_type] = content_type.to_s if content_type.present?

      list(all_filters)
    end

    # Récupère par account_id unique (GET route)
    def self.get_by_account(account_id, page: 1, per_page: 10)
      return [] if account_id.blank?

      account_id = account_id.to_i  # ✅ Convertir en Integer
      puts "📤 [HistoryClient] Fetching watch histories for account_id: #{account_id}"
      path = "/internal/api/v1/watch-histories/by-account/#{account_id}"

      params = { page: page.to_i, per_page: per_page.to_i }  # ✅ Convertir en Integer
      response = request(:get, path, params: params)

      puts "✅ [HistoryClient] Response: #{response.inspect}"
      return [] if response.blank? || response[:error]
      response || []
    rescue StandardError => e
      Rails.logger.error "[HistoryClient] Failed to fetch watch history for account: #{e.message}"
      puts "❌ [HistoryClient] Error: #{e.message}"
      []
    end

    # Récupère les stats
    def self.get_stats(account_ids = [])
      puts "📤 [HistoryClient] Fetching stats for account_ids: #{account_ids}"
      path = "/internal/api/v1/watch-histories/stats"

      params = {}
      if account_ids.present?
        # ✅ Convertir les account_ids en array d'integers
        account_ids_array = account_ids.is_a?(Array) ? account_ids : [account_ids]
        account_ids_array = account_ids_array.map(&:to_i)
        params[:account_ids] = account_ids_array.join(',')
      end

      response = request(:get, path, params: params)

      puts "✅ [HistoryClient] Stats: #{response.inspect}"
      return {} if response.blank? || response[:error]
      response || {}
    rescue StandardError => e
      Rails.logger.error "[HistoryClient] Failed to fetch stats: #{e.message}"
      puts "❌ [HistoryClient] Error: #{e.message}"
      {}
    end

    # ✅ Sanitize récursif : clés en String, Symbols en String, Date/Time en iso8601
    def self.deep_sanitize(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), result|
          result[k.to_s] = deep_sanitize(v)
        end
      when Array
        obj.map { |v| deep_sanitize(v) }
      when Symbol
        obj.to_s
      when Date, Time, DateTime
        format_date(obj)
      else
        obj
      end
    end

    # ✅ Formatte une date/heure en string ISO8601, gère aussi les strings déjà formatées
    def self.format_date(value)
      return nil if value.blank?
      value.respond_to?(:iso8601) ? value.iso8601 : value.to_s
    end
  end
end