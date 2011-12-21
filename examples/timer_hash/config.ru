# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'rumx'
require 'my_bean'

Rumx::Bean.root.bean_add_child(:MyBean, MyBean.new)
run Rumx::Server
