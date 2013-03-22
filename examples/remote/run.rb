raise 'Must set environment variable RUMX_SERVERS' unless ENV['RUMX_SERVERS']

require 'rubygems'
require 'rumx'
require './remote_client'
require './remote_root'

Rumx::Bean.add_root(:remote, RemoteRoot.new(ENV['RUMX_SERVERS'].split))
