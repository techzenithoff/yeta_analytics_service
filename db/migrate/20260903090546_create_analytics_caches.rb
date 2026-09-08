class CreateAnalyticsCaches < ActiveRecord::Migration[6.1]
  def change
    create_table :analytics_caches do |t|
      t.string :cache_key, null: false, index: { unique: true }
      t.json :data
      t.datetime :expires_at

      t.timestamps
    end

    add_index :analytics_caches, :expires_at
  end
end