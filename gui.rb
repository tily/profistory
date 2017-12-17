require_relative './core'

class Profistory
  class GUI < Core
    register Sinatra::Namespace
    register Kaminari::Helpers::SinatraHelpers
    enable :sessions
    set :session_secret, Settings.session.secret
    set :protection, :except => :path_traversal
    use Rack::Session::Moneta, store: Moneta.new(:Mongo, host: "db")
    use Rack::Locale
    set :haml, ugly: true, escape_html: true
    case Settings.auth.provider
    when "twitter"
      use OmniAuth::Builder do
        provider :twitter, Settings.auth.twitter.consumer_key, Settings.auth.twitter.consumer_secret
      end
    when "saml"
      use OmniAuth::Strategies::SAML,
        assertion_consumer_service_url: Settings.auth.saml.assertion_consumer_service_url,
        issuer:                         Settings.auth.saml.issuer,
        idp_sso_target_url:             Settings.auth.saml.idp_sso_target_url,
        idp_cert_fingerprint:           Settings.auth.saml.idp_cert_fingerprint,
        name_identifier_format:         Settings.auth.saml.name_identifier_format
    end
    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    I18n.load_path = Dir['config/locales/*.yml']
    I18n.backend.load_translations

    respond_to :html

    [:get, :post].each do |method|
      send(method, '/auth/:provider/callback') do
        auth = request.env["omniauth.auth"]
        user = User.where(:provider => auth["provider"], :uid => auth["uid"]).first
        if user
          user.update_with_omniauth(auth)
        else
          User.create_with_omniauth(auth)
        end
        session[:uid] = auth["uid"]
        redirect to("users/#{current_user.name}")
      end
    end

    before do
      pass if request.path_info =~ /^\/auth\//
    end
    
    get '/logout' do
      session[:uid] = nil
      redirect to('/')
    end

    get '/' do
      @users = User.desc(:created_at).limit(20)
      @works = Work.desc(:created_at).limit(20)
      @tags = Tag.all[0, 20]
      haml :list_all
    end

    namespace '/works' do
      get                   { list_works  }
      get('/:title')        { show_work   }

      get '/:title/edit' do
        @work = Work.where(:title => CGI.unescape(params[:title])).first
        haml :edit_work
      end

      post                  { create_work }
      post('/:title/join')  { join_work   }
      post('/:title/leave') { leave_work  }
    end
    
    namespace '/users' do
      get('/:user_name')  { show_user   }
      post('/:user_name') { update_user }
      get                 { list_users  }
    end
    
    namespace '/tags' do
      get           { list_tags }
      get('/:name') { show_tag  }
    end
  end
end
