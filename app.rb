require 'sinatra'
require 'omniauth-twitter'

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

