# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'rumx'
require 'my_bean'

parent = Rumx::FolderBean.new
Rumx::Bean.root.bean_register_child('MyFolder', parent)
parent.bean_register_child('MyBean', MyBean.new)
run Rumx::Server::App
