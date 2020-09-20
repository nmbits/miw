
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

  v = MiW::TableView.new :table, dataset: dataset, show_label: true
  v.show

  v.add_column MiW::TableView::TextColumn.new(:name, "Name", min: 20, max: 150)
  v.add_column MiW::TableView::TextColumn.new(:active, "Active", min: 30, max: 150, resize: true)
  v.add_column MiW::TableView::TextColumn.new(:created_at, "Created At", width: 240, min: 30, resize: true)

  sv = MiW::ScrollView.new :sv, horizontal: false
  w.add_child sv, resize: [true, true]

  sv.target = v
  # w.add_child v, resize: [true, true]
  w.show

  MiW.run
end
