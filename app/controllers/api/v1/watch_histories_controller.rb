 module Api::V1
  class WatchHistoriesController < ApiController

    #before_action :authenticate_account!#, only: [:create, :destroy]

     before_action :authenticate!

    before_action :set_watch_history, only: [:show, :update, :destroy]

    # GET /watch_histories
    def index
      @watch_histories = WatchHistory.where(account_id: current_account_id).order(last_watched_at: :desc)

        # Appels inter-services : récupération des métadonnées via HTTP
        #render json: histories.map { |h| serialize_history(h) }

      render json: @watch_histories
    end

    def my_histories
        # 1. Extraction et sécurisation des paramètres de pagination
        page = params.fetch(:page, 1).to_i.clamp(1, Float::INFINITY).to_i
        per_page = params.fetch(:per_page, 20).to_i.clamp(1, 50)

        # 2. Appel du service d'agrégation pour l'utilisateur courant
        histories_data = WatchHistories::WatchHistoriesService.my_histories(current_account_id, page: page, per_page: per_page)

        # 3. Réponse JSON propre
        render json: {
            status: 200,
            watch_histories: histories_data[:items],
            meta: {
                page: page,
                per_page: per_page,
                total_count: histories_data[:total_count],
                total_pages: histories_data[:total_pages]
            }
        }, status: :ok

    rescue StandardError => e
        # 4. Gestion de secours (Fallback / Résilience) si un service distant crash totalement
        Rails.logger.error("Erreur lors de la récupération de l'historique pour l'utilisateur #{current_account_id}: #{e.message}")
        render json: {
            success: false,
            error: "Impossible de charger l'historique pour le moment. Veuillez réessayer plus tard."
        }, status: :service_unavailable
    end

    # GET /watch_histories/1
    def show
      render json: @watch_history
    end

    # POST /watch_histories
    def create_OLD
      @watch_history = WatchHistory.new(watch_history_params)

      if @watch_history.save
        render json: @watch_history, status: :created, location: @watch_history
      else
        render json: @watch_history.errors, status: :unprocessable_entity
      end
    end

    def create_LAST
        history = WatchHistory.find_or_initialize_by(
            account_id: current_account_id,
            watchable_type: params[:watchable_type],
            watchable_id: params[:watchable_id]
        )

        history.duration_seconds ||= params[:duration_seconds]
        history.update_position!(params[:position_seconds].to_i)

        render json: serialize_history(history), status: :ok

      end

    def create



        watchable_type = params[:watchable_type]&.strip
        watchable_id = params[:watchable_id]&.to_i
        position_seconds = params[:position_seconds]
        duration_seconds = params[:duration_seconds]

        puts "PARAMS: #{watchable_id.inspect}"

        # 1. Vérification des paramètres requis
        unless watchable_type.present? && watchable_id.present?
            return render json: {
                status: 422,
                message: "Paramètres invalides.",
                errors: { base: ["watchable_type et watchable_id sont requis."] }
            }, status: :unprocessable_entity
        end

        puts "AFTER"
        # 2. Recherche ou initialisation de l'historique
        history = WatchHistory.find_or_initialize_by(
            account_id: current_account_id,
            watchable_type: watchable_type,
            watchable_id: watchable_id, 
            account_id: current_account_id
        )

        # Génération d'un UID si c'est une création (si tu utilises un has_secure_token ou un UUID par défaut)
        # history.uuid ||= SecureRandom.uuid if history.new_record? && history.respond_to?(:uid=)

        # 3. Assignation des valeurs avec vérifications
        history.duration_seconds = duration_seconds.to_i if duration_seconds.present?
        
        # Gestion de la position et mise à jour via ta méthode dédiée
        if position_seconds.present?
            history.update_position!(position_seconds.to_i)
        else
            history.save!
        end

        #render json: serialize_history(history), status: :ok
        render json: history, status: :ok

    rescue ActiveRecord::RecordInvalid => e
        render json: {
            status: 422,
            message: "Erreur de validation.",
            errors: e.record.errors.full_messages
        }, status: :unprocessable_entity
    rescue => e
        Rails.logger.error "[WatchHistoryController] Erreur lors de la création : #{e.message}"
        render json: {
            status: 500,
            message: "Une erreur interne est survenue."
        }, status: :internal_server_error
    end

    # PATCH/PUT /watch_histories/1
    def update
      if @watch_history.update(watch_history_params)
        render json: @watch_history
      else
        render json: @watch_history.errors, status: :unprocessable_entity
      end
    end

    # DELETE /watch_histories/1
    def destroy
      
      begin
                
                 @watch_history.destroy

                render json: { message: "Élément supprimé avec succès",  status: 200}, status: :ok

            rescue => e
                render json: {message: "Erreur lors de la suppression de l'élément dans l'historique de lecture.", errors: e.message, status: 500}, status: :internal_server_error
            end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_watch_history
        @watch_history = WatchHistory.find_by(uuid: params[:id])
      end

      # Only allow a list of trusted parameters through.
      def watch_history_params
        params.require(:watch_history).permit(:uuid, :watchable_id, :account_id, :started_at, :last_watched_at, :position_seconds, :duration_seconds, :completed)
      end

      # Enrichir la réponse avec les infos du contenu distant
      def serialize_history(history)
        content = fetch_watchable(history.watchable_type, history.watchable_id)
        {
            id: history.id,
            progress: history.progress_percent,
            completed: history.completed,
            last_watched_at: history.last_watched_at,
            watchable: content
        }
      end
  end
end