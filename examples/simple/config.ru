# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'rumx'
require 'my_bean'

parent = Rumx::FolderBean.new
Rumx::Bean.root.bean_register_child('My Folder', parent)
parent.bean_register_child('My Bean', MyBean.new)
run Rumx::Server
