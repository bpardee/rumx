# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'rumx'

memory_bean = Rumx::JMXBean.new('java.lang:type=Memory')
os_bean = Rumx::JMXBean.new('java.lang:type=OperatingSystem')
threading_bean = Rumx::JMXBean.new('java.lang:type=Threading')
Rumx::Bean.root.bean_add_child(:Memory, memory_bean)
Rumx::Bean.root.bean_add_child(:OperatingSystem, os_bean)
Rumx::Bean.root.bean_add_child(:Threading, threading_bean)
run Rumx::Server
