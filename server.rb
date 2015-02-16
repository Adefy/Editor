require "bundler/setup"
Bundler.require
Mongoid.load!("#{File.dirname(__FILE__)}/config/mongoid.yml")

require "fileutils"
require "sinatra/reloader"
require "sinatra/json"
require "sinatra/content_for"
require "sinatra/assetpack"
require "better_errors"
require "pathname"
require "stylus"
require "stylus/tilt"

require_relative "models/user"
require_relative "lib/warden"

class Editor < Sinatra::Base
  register Sinatra::Reloader
  also_reload "lib/*.rb"
  also_reload "models/*.rb"

  helpers Sinatra::ContentFor
  helpers Sinatra::JSON

  set :server, :thin
  set :port, 5813

  use Rack::MethodOverride
  use Rack::Session::Cookie, secret: "woahwoahwoahwoah"
  use Rack::Flash

  register Sinatra::WardenAuth
  register Sinatra::AssetPack

  assets {
    serve "/coffee", from: "#{File.dirname(__FILE__)}/editor/coffee"
    serve "/styles", from: "#{File.dirname(__FILE__)}/editor/styles"

    js_compression  :yui
    css_compression :yui
    cache_dynamic_assets true
  }

  get "/" do
    slim :editor
  end

  configure :development do
    use BetterErrors::Middleware
    BetterErrors.application_root = File.expand_path("..", __FILE__)
  end

  # Start the server if ruby file executed directly
  run! if app_file == $0
end
