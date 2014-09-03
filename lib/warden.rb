require "sinatra/base"

module Sinatra
  module WardenAuth

    module Helpers
      def warden
        env["warden"]
      end

      def current_user
        warden.user
      end

      def check_authentication
        redirect "/login" unless warden.authenticated?
      end
    end

    def self.registered(app)
      app.helpers WardenAuth::Helpers

      app.use Warden::Manager do |config|
        config.serialize_into_session{ |user| user.id }
        config.serialize_from_session{ |id| User.find(id) }

        config.scope_defaults :default,
          strategies: [:password],
          action: "auth/unknown_user"

        config.failure_app = app
      end

      Warden::Manager.before_failure do |env, opts|
        env["REQUEST_METHOD"] = "POST"
      end

      Warden::Strategies.add(:password) do
        def valid?
          params["user"]["username"] && params["user"]["password"]
        end

        def authenticate!
          user = User.where(username: params["user"]["username"]).first

          if !user.nil? && user.authenticate(params["user"]["password"])
            success!(user)
          else
            fail!("The username or password you entered is incorrect.")
          end
        end
      end

      app.before do
        pass if ["/login", "/logout", "/auth/unknown_user"].include? request.path_info
        check_authentication
      end

      app.get "/login" do
        slim :login
      end

      app.post "/login" do
        warden.authenticate!
        flash[:success] = env["warden"].message

        if session[:return_to] && session[:return_to] != "/login"
          redirect session[:return_to]
        else
          redirect "/"
        end
      end

      app.get "/logout" do
        warden.logout
        redirect "/"
      end

      app.post "/auth/unknown_user" do
        session[:return_to] = env["warden.options"][:attempted_path]
        flash[:error] = warden.message || "There was an error"
        redirect "/login"
      end

    end
  end

  register WardenAuth
end
