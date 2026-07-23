class CreateRatings < ActiveRecord::Migration[6.1]
  def change
    create_table :ratings do |t|
      
      t.uuid :uuid, null: false
      t.references :ratable, polymorphic: true, index: true
      t.integer :rating,  default: 0      # Note de 1 à 5
      t.text :comment                     # Optionnel
      t.references :account, null: false, index: true

      t.timestamps
    end

    # Empêche un utilisateur de noter plusieurs fois la même entité, tout en permettant la mise à jour
    #add_index :ratings, [:account_id, :ratable_id, :ratable_type], unique: true, name: 'index_ratings_uniqueness' # Gérér sur le model
    
  end
end