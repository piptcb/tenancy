require 'active_record'
require 'logger'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'spec/test.sqlite3')
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :portals, :force => true do |t|
    t.string :domain_name
    t.timestamps
  end

  create_table :listings, :force => true do |t|
    t.string :name
    t.references :portal
    t.boolean :is_active
    t.timestamps
  end

  create_table :communications, :force => true do |t|
    t.string :label
    t.string :value
    t.references :listing
    t.references :portal
    t.boolean :is_active
    t.timestamps
  end

  create_table :extra_communications, :force => true do |t|
    t.string :label
    t.string :value
    t.references :listing
    t.references :portal
    t.timestamps
  end
end
