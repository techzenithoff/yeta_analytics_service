class CreateWatchHistories < ActiveRecord::Migration[6.1]
  def change
    create_table :watch_histories do |t|
      t.uuid :uuid, null: false
      t.references :watchable, polymorphic: true, index: true
      t.bigint :account_id, null: false, index: true
      t.datetime :started_at
      t.datetime :last_watched_at
      t.integer :position_seconds
      t.integer :duration_seconds
      t.boolean :completed

      t.timestamps
    end
  end
end
