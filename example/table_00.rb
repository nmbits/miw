
require 'bundler/setup'
require 'miw'
require 'sequel'

if __FILE__ == $0
  w = MiW::Window.new("menu", 10, 10, 400, 400, layout: MiW::Layout::VBox)
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  DB = Sequel.sqlite

  DB.create_table :items do
    primary_key :id
    String :name, unique: true, null: false
    TrueClass :active, default: true
    DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP, :index=>true
  end

  dataset = DB[:items]

  100.times do |i|
    dataset.insert name: "item_#{i}"
  end

  v = MiW::TableView.new "table", dataset: dataset
  v.add_column_def :name, "Name"
  v.add_column_def :active, "Active"
  v.add_column_def :created_at, "Created At"

  v.show
  w.add_child v, resize: [true, true]
  w.show

  MiW.run
end
