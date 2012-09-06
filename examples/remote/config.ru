# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

raise 'Must set environment variable RUMX_SERVERS' unless ENV['RUMX_SERVERS']

require 'rubygems'
require 'rumx'
require './remote_loader'
require './remote_client'
require './remote_root'

use RemoteLoader
Rumx::Bean.add_root(:remote, RemoteRoot.new(ENV['RUMX_SERVERS'].split))
run Rumx::Server
