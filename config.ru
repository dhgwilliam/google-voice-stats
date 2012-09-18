$:.unshift File.dirname(__FILE__)
$LOAD_PATH << './models'
require 'routes'
require 'helpers'

require 'person'

Ohm.connect(:db => "15")
run Sinatra::Application
