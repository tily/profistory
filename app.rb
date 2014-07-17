require 'sinatra'
require 'omniauth-twitter'
require 'mongoid'

if ENV['MONGOHQ_URL']
	uri = URI.parse(ENV['MONGOHQ_URL'])
	database = Mongo::Connection.new(uri.host, uri.port).db(uri.path.gsub(/^\//, ''))
	database.authenticate(uri.user, uri.password) unless (uri.user.nil? || uri.password.nil?)
	Mongoid.database = database
else
	Mongoid.database = Mongo::Connection.new('localhost', Mongo::Connection::DEFAULT_PORT).db('nnade_development')
end

configure do
	enable :sessions
	use OmniAuth::Builder do
		provider :twitter, ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
	end
end

helpers do
	def current_user
		!session[:uid].nil?
	end
end

before do
	pass if request.path_info =~ /^\/auth\//
	redirect to('/auth/twitter') unless current_user
end

get '/auth/twitter/callback' do
	session[:uid] = env['omniauth.auth']['uid']
	redirect to('/')
end

get '/auth/failure' do
end

get '/' do
	'Hello omniauth-twitter!'
end

