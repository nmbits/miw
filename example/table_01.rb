
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

  dataset = MiW::Util::DirectoryDataSet.new("/usr/include")

  v = MiW::TableView.new :table, dataset: dataset, show_label: true
  v.show

  v.add_column MiW::TableView::TextColumn.new(:name, "Name", min: 20, max: 150)
  v.add_column MiW::TableView::TextColumn.new(:size, "Size", min: 30, max: 150, resize: true)
  v.add_column MiW::TableView::TextColumn.new(:mtime, "mtime", width: 240, min: 30, resize: true)

  w.add_child v, resize: [true, true]
  w.show

  MiW.run
end
