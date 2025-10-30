namespace :deploy do
  desc "Copy Swagger docs to public folder"
  task :copy_swagger do
    on roles(:app) do
      within release_path do

        execute :rm, "-rf", "#{release_path}/public/api-docs"
        # Crée le dossier public/api-docs/v1 si nécessaire
        execute :mkdir, "-p", "#{release_path}/public/api-docs/v1"

        # Copie les fichiers Swagger depuis le repo vers public
        execute :cp, "-rf", "#{release_path}/swagger/v1/*", "#{release_path}/public/api-docs/v1/"
      end
    end
  end
end

# Hook pour exécuter après 'deploy:updated' (après mise à jour du code)
#after 'deploy:updated', 'deploy:copy_swagger'
