module Api
    module V1
        class RatingsController < ApiController

            before_action :authenticate!, only: [:create]


            # GET /api/v1/ratings/summary?ratable_type=Episode&ratable_id=xxx
            def summary

                ratable_type = params[:ratable_type]&.strip
                ratable_id = params[:ratable_id]&.to_i



                # 1. Vérification des paramètres requis
                unless ratable_type.present? && ratable_id.present?
                    return render json: {
                        status: 422,
                        message: "Paramètres invalides.",
                        errors: { base: ["ratable_type et ratable_id sont requis."] }
                    }, status: :unprocessable_entity
                end



                summary_data = Rating.summary_for(params[:ratable_type], params[:ratable_id])
                render json: summary_data, status: :ok

            rescue StandardError => e
                # 4. Gestion de secours (Fallback / Résilience) si un service distant crash totalement
                Rails.logger.error("Erreur lors de la récuperation du résume: #{current_account_id}: #{e.message}")
                render json: {
                    success: false,
                    error: "Impossible de récuperer le resumé pour le moment. Veuillez réessayer plus tard."
                }, status: :service_unavailable
            end

            # POST /api/v1/ratings
            def create


                @rating = Rating.find_or_initialize_by(
                    account_id: current_account_id,
                    ratable_id: rating_params[:ratable_id],
                    ratable_type: rating_params[:ratable_type]
                )

                @rating.rating = rating_params[:rating]
                @rating.comment = rating_params[:comment] if rating_params[:comment].present?

                if @rating.save
                    # Optionnel : Publier un événement RabbitMQ ici pour informer les autres services de la nouvelle moyenne
                    render json: { status: 201, message: "Note enregistrée avec succès", rating: @rating }, status: :created
                else
                    render json: { errors: @rating.errors.full_messages }, status: :unprocessable_entity
                end
            rescue StandardError => e
                # 4. Gestion de secours (Fallback / Résilience) si un service distant crash totalement
                Rails.logger.error("Erreur lors du vote pour l'utilisateur: #{current_account_id}: #{e.message}")
                render json: {
                    success: false,
                    error: "Impossible de voter pour le moment. Veuillez réessayer plus tard."
                }, status: :service_unavailable
            end

            private

            def rating_params
                params.require(:rating).permit(:ratable_id, :ratable_type, :rating)
            end
        end
    end
end