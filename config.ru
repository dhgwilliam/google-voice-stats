$:.unshift File.dirname(__FILE__)
$LOAD_PATH << './models'
$LOAD_PATH << './lib'
require 'routes'
require 'helpers'
require 'person'
require 'rack/cache'
require 'resque'
require 'queues'

use Rack::Cache,
  :verbose     => true,
  :metastore   => 'file:tmp/cache/rack/meta',
  :entitystore => 'file:tmp/cache/rack/body',
  :allow_reload => true

Ohm.connect(:db => "15")

run Sinatra::Application
