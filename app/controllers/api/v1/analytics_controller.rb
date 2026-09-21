# app/controllers/api/v1/analytics_controller.rb
# frozen_string_literal: true

module Api
    module V1
        class AnalyticsController < ApplicationController
            before_action :parse_filters
            before_action :handle_circuit_breaker_error, only: [:summary, :clients_by_country, :content_breakdown, :demographics]

            # GET /api/v1/analytics/summary
            def summary
                watch_histories = fetch_watch_histories(include_content_type: true)

                if watch_histories.blank?
                    # Filtre content_type actif sans résultat : réponse vide valide, pas une panne
                    return render json: build_summary_response([], []) if @filters[:content_type].present?

                    return render json: build_error_response('No watch history data available', 'degraded'), status: 503
                end

                account_ids = extract_account_ids(watch_histories)
                return render json: build_error_response('No accounts found', 'degraded'), status: 503 if account_ids.blank?

                customers = fetch_customers(account_ids)
                return render json: build_error_response('No customers data', 'degraded'), status: 503 if customers.blank?

                customers = filter_customers_by_demographics(customers, @filters)
                filtered_account_ids = extract_account_ids(customers)
                watch_histories = watch_histories.select { |wh| filtered_account_ids.include?(wh['account_id']) }

                render json: build_summary_response(customers, watch_histories)
            end

            # GET /api/v1/analytics/clients_by_country
            def clients_by_country
                watch_histories = fetch_watch_histories(include_content_type: true)

                if watch_histories.blank?
                    # Filtre content_type actif sans résultat : réponse vide valide, pas une panne
                    if @filters[:content_type].present?
                        return render json: {
                            period: { from: @filters[:date_from], to: @filters[:date_to] },
                            data: [],
                            status: 'ok'
                        }
                    end

                    return render json: build_error_response('No watch history data', 'degraded'), status: 503
                end

                account_ids = extract_account_ids(watch_histories)
                return render json: build_error_response('No accounts found', 'degraded'), status: 503 if account_ids.blank?

                customers = fetch_customers(account_ids)
                return render json: build_error_response('No customers data', 'degraded'), status: 503 if customers.blank?

                customers = filter_customers_by_demographics(customers, @filters)

                rows = customers
                        .reject { |c| c['country'].blank? }
                        .group_by { |c| c['country'] }
                        .transform_values(&:size)
                        .sort_by { |_, count| -count }
                        .map { |country, count| { country: country, customers: count } }

                render json: {
                period: { from: @filters[:date_from], to: @filters[:date_to] },
                data: rows,
                status: 'ok'
                }
            end

            # GET /api/v1/analytics/content_breakdown
            def content_breakdown
                watch_histories = fetch_watch_histories(include_content_type: false)

                if watch_histories.blank?
                return render json: build_error_response('No watch history data', 'degraded'), status: 503
                end

                by_type = watch_histories
                            .group_by { |wh| wh['watchable_type'] }
                            .transform_values(&:size)
                            .sort_by { |_, count| -count }
                            .map { |type, count|
                            {
                                content_type: (type || "Unknown").underscore,
                                views: count
                            }
                            }

                top_titles = watch_histories
                            .reject { |wh| wh['watchable_type'].blank? || wh['watchable_id'].blank? }
                            .group_by { |wh| [wh['watchable_type'], wh['watchable_id']] }
                            .transform_values(&:size)
                            .sort_by { |_, count| -count }
                            .take(10)
                            .map { |(type, id), count|
                                {
                                content_type: (type || "Unknown").underscore,
                                watchable_id: id,
                                title: resolve_title(type, id),
                                views: count
                                }
                            }

                render json: {
                period: { from: @filters[:date_from], to: @filters[:date_to] },
                by_type: by_type,
                top_titles: top_titles,
                status: 'ok'
                }
            end

            # GET /api/v1/analytics/demographics
            def demographics
                watch_histories = fetch_watch_histories(include_content_type: false)

                if watch_histories.blank?
                return render json: build_error_response('No watch history data', 'degraded'), status: 503
                end

                account_ids = extract_account_ids(watch_histories)
                return render json: build_error_response('No accounts found', 'degraded'), status: 503 if account_ids.blank?

                customers = fetch_customers(account_ids)
                return render json: build_error_response('No customers data', 'degraded'), status: 503 if customers.blank?

                by_gender = customers
                            .reject { |c| c['civility'].blank? }
                            .group_by { |c| map_civility_to_gender(c['civility']) }
                            .transform_values(&:size)
                            .map { |gender, count| { gender: gender, customers: count } }
                            .sort_by { |row| -row[:customers] }

                by_age = build_age_breakdown(customers)

                render json: {
                period: { from: @filters[:date_from], to: @filters[:date_to] },
                by_gender: by_gender,
                by_age: by_age,
                status: 'ok'
                }
            end

            # GET /api/v1/analytics/circuit-breaker-status
            def circuit_breaker_status
                render json: {
                profile_service: get_circuit_status("profile-service"),
                watch_history_service: get_circuit_status("watch-history-service"),
                timestamp: Time.current.iso8601
                }
            end

            private

            # ✅ Centralise l'appel à HistoryClient avec les bons filtres (date_from/date_to inclus)
            # ✅ Normalise toujours le retour en Array de Hash (sécurise contre {error: ...} ou {"data" => [...]})
            def fetch_watch_histories(include_content_type:)
                content_type = include_content_type ? @filters[:content_type] : nil

                response = WatchHistory::HistoryClient.list_by_period_and_type(
                @filters[:date_from],
                @filters[:date_to],
                content_type
                )

                normalize_records(response)
            end

            # ✅ Centralise l'appel à CustomerClient avec normalisation identique
            def fetch_customers(account_ids)
                response = Profiles::CustomerClient.fetch_by_account_ids(account_ids)

                # Le client renvoie un Hash indexé par account_id ({17 => {...}}) : on ne garde que les valeurs
                return response.values if response.is_a?(Hash) && response.values.all?(Hash)

                normalize_records(response)
            end

            # ✅ Garantit toujours un Array de Hash, quel que soit le format renvoyé par le client HTTP
            def normalize_records(response)
                return [] if response.blank?
                return [] if response.is_a?(Hash) && response[:error]

                case response
                when Array
                response
                when Hash
                extracted = response['data'] || response[:data] ||
                            response['watch_histories'] || response[:watch_histories] ||
                            response['customers'] || response[:customers]
                extracted.is_a?(Array) ? extracted : []
                else
                []
                end
            end

            def parse_filters
                @filters = {
                country: params[:country].presence,
                content_type: normalize_content_type(params[:content_type]),
                gender: params[:gender].presence,
                age_min: params[:age_min].to_i,
                age_max: params[:age_max].to_i,
                date_from: parse_date(params[:date_from]),
                date_to: parse_date(params[:date_to]) || Date.current
                }
            end

            def handle_circuit_breaker_error
                # Les services vont retourner des {} si circuit ouvert
                # La logique au-dessus gère déjà le fallback
            end

            def build_error_response(message, status = 'error')
                { error: message, status: status }
            end

            def build_summary_response(customers, watch_histories)
                total_views = watch_histories.size
                total_seconds = watch_histories.sum { |wh| (wh['duration_seconds'] || 0).to_i }
                completed_count = watch_histories.count { |wh| wh['completed'] == true }
                completion_rate = total_views.positive? ?
                                    (completed_count.to_f / total_views).round(4) : 0.0

                top_countries = customers
                                .reject { |c| c['country'].blank? }
                                .group_by { |c| c['country'] }
                                .transform_values(&:size)
                                .sort_by { |_, count| -count }
                                .take(5)
                                .map { |country, count| { country: country, customers: count } }

                {
                period: { from: @filters[:date_from], to: @filters[:date_to] },
                totals: {
                    active_customers: customers.size,
                    total_views: total_views,
                    total_seconds: total_seconds,
                    total_hours: (total_seconds / 3600.0).round(2),
                    completed_views: completed_count,
                    completion_rate: completion_rate
                },
                top_countries: top_countries,
                status: 'ok'
                }
            end

            def build_age_breakdown(customers)
                by_age = Hash.new(0)
                customers.each do |customer|
                next if customer['birth_date'].blank?
                begin
                    birth_date = Date.parse(customer['birth_date'])
                    age = ((Date.current - birth_date) / 365.25).to_i
                    bucket = bucket_for(age)
                    by_age[bucket] += 1
                rescue ArgumentError
                    # Ignore invalid dates
                end
                end

                by_age.sort.map { |bucket, count| { bucket: bucket, customers: count } }
            end

            def extract_account_ids(records)
                records.map { |r| r['account_id'] }.compact.uniq
            end

            def parse_date(value)
                return nil if value.blank?
                Date.parse(value.to_s)
            rescue ArgumentError
                nil
            end

            def normalize_content_type(value)
                return nil if value.blank?
                case value.to_s.downcase
                when "movie" then "Movie"
                when "episode" then "Episode"
                when "emission", "émission" then "Emission"
                else nil
                end
            end

            def filter_customers_by_demographics(customers, filters)
                result = customers

                if filters[:gender].present?
                result = result.select { |c|
                    map_civility_to_gender(c['civility']) == filters[:gender]
                }
                end

                if filters[:age_min].positive? || filters[:age_max].positive?
                result = result.select do |c|
                    next false if c['birth_date'].blank?
                    begin
                    birth_date = Date.parse(c['birth_date'])
                    age = ((Date.current - birth_date) / 365.25).to_i

                    age_ok = true
                    age_ok = age >= filters[:age_min] if filters[:age_min].positive?
                    age_ok = age <= filters[:age_max] if filters[:age_max].positive?

                    age_ok
                    rescue ArgumentError
                    false
                    end
                end
                end

                result
            end

            def map_civility_to_gender(civility)
                return "unknown" if civility.blank?
                case civility.to_s.upcase.strip
                when 'M', 'MR', 'MONSIEUR' then 'M'
                when 'MRS', 'MME', 'MLLE', 'MS', 'MADAME' then 'F'
                else 'unknown'
                end
            end

            def bucket_for(age)
                case age
                when 0..17 then "0-17"
                when 18..24 then "18-24"
                when 25..34 then "25-34"
                when 35..44 then "35-44"
                when 45..54 then "45-54"
                when 55..64 then "55-64"
                else "65+"
                end
            end

            def resolve_title(type, id)
                "#{type} ##{id}"
            end

            def get_circuit_status(service_name)
                circuit = Circuitbox.circuit(service_name.to_sym)
                {
                state: circuit.send(:state),
                success_count: circuit.send(:success_count),
                failure_count: circuit.send(:failure_count)
                }
            rescue => e
                Rails.logger.error("Error getting circuit status for #{service_name}: #{e.message}")
                { state: 'unknown', error: e.message }
            end
        end
    end
end