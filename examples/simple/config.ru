# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'rumx'
require 'my_bean'

my_folder = Rumx::FolderBean.new
Rumx::Bean.root.bean_add_child('My Folder', my_folder)
my_folder.bean_add_child('My Bean', MyBean.new)
run Rumx::Server
