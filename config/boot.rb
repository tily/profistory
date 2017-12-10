configure do
  register Config
  register Kaminari::Helpers::SinatraHelpers
  enable :sessions
  set :session_secret, Settings.session.secret
  set :haml, ugly: true, escape_html: true
  set :protection, :except => :path_traversal
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
  use Rack::Session::Moneta, store: Moneta.new(:Mongo, host: "db")
  Mongoid.load!("config/mongoid.yml")
end
