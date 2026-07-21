# config/initializers/pagy.rb
require 'pagy/extras/metadata'
require 'pagy/extras/overflow' # Optionnel : gère les pages hors limites
require 'pagy/extras/items'

# Config par défaut
Pagy::DEFAULT[:items] = 20 # Nombre d'items par page
Pagy::DEFAULT[:overflow] = :last_page # Si la page demandée est trop haute, retourne la dernière
Pagy::DEFAULT[:metadata] = [:count, :page, :items, :pages, :next, :prev, :last]
Pagy::DEFAULT[:max_items] = 100