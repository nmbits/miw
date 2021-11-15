
require 'bundler/setup'
require 'miw'
require 'miw/table_view'
require 'miw/util/directory_data_set'

if __FILE__ == $0
  w = MiW::Window.new("table", 10, 10, 400, 400, layout: MiW::Layout::VBox)
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  dataset = MiW::Util::DirectoryDataSet.new(".")

  v = MiW::TableView.new :table, dataset: dataset, show_label: true
  v.show

  v.add_column MiW::TableView::TextColumn.new(:name, "Name", min: 20, resize: true)
  v.add_column MiW::TableView::TextColumn.new(:size, "Size", min: 30, max: 150, resize: true)
  v.add_column MiW::TableView::TextColumn.new(:mtime, "mtime", width: 240, min: 30, resize: true)

  sv = MiW::ScrollView.new :sc, vertical: true, layout: MiW::Layout::VBox
  sv.set_target v, resize: [true, true]

  w.add_child sv, resize: [true, true]
  w.show

  MiW.run
end
