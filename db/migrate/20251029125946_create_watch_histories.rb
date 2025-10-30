class CreateWatchHistories < ActiveRecord::Migration[6.1]
  def change
    create_table :watch_histories do |t|
      t.string :uid
      t.references :watchable, polymorphic: true, index: true
      t.references :account, index: true #null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :last_watched_at
      t.integer :position_seconds
      t.integer :duration_seconds
      t.boolean :completed

      t.timestamps
    end
  end
end
