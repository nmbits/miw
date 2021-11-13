
require 'bundler/setup'
require 'miw'
require 'miw/table_view'
require 'miw/model/data_set'

if __FILE__ == $0
  w = MiW::Window.new("table", 10, 10, 400, 400, layout: MiW::Layout::VBox)
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  dataset = MiW::Model::DataSet.new

  100.times do |i|
    dataset.insert id: i, active: true, name: "item_#{i}", created_at: Time.now
  end
  # pp dataset

  v = MiW::TableView.new :table, dataset: dataset, show_label: true
  v.show

  v.add_column MiW::TableView::TextColumn.new(:name, "Name", min: 20, max: 150)
  v.add_column MiW::TableView::TextColumn.new(:active, "Active", min: 30, max: 150, resize: true)
  v.add_column MiW::TableView::TextColumn.new(:created_at, "Created At", width: 240, min: 30, resize: true)

  w.add_child v, resize: [true, true]
  w.show

  MiW.run
end
