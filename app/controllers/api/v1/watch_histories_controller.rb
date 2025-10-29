 module Api::V1
  class WatchHistoriesController < ApiController

    before_action :authenticate_account!#, only: [:create, :destroy]

    before_action :set_watch_history, only: [:show, :update, :destroy]

    # GET /watch_histories
    def index
      histories = WatchHistory.where(account_id: current_account_id).order(last_watched_at: :desc)

        # Appels inter-services : récupération des métadonnées via HTTP
        render json: histories.map { |h| serialize_history(h) }

      #render json: @watch_histories
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

     def create
        history = WatchHistory.find_or_initialize_by(
          account_id: current_account_id,
          watchable_type: params[:watchable_type],
          watchable_id: params[:watchable_id]
        )

        history.duration_seconds ||= params[:duration_seconds]
        history.update_position!(params[:position_seconds].to_i)

        render json: serialize_history(history), status: :ok
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
      @watch_history.destroy
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_watch_history
        @watch_history = WatchHistory.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def watch_history_params
        params.require(:watch_history).permit(:uid, :watchable_id, :account_id, :started_at, :last_watched_at, :position_seconds, :duration_seconds, :completed)
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