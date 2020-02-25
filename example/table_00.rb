
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

  columns = [
    {key: :name,       display_name: "Name"},
    {key: :active,     display_name: "Active"},
    {key: :created_at, display_name: "Created At"}
  ]

  v.columns = columns

  v.show
  w.add_child v, resize: [true, true]
  w.show

  MiW.run
end
