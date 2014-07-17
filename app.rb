# coding: utf-8
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

class User
	include Mongoid::Document
	include Mongoid::Timestamps # adds created_at and updated_at fields
	field :screen_name, :type => String
	field :uid, :type => String
	field :provider, :type => String
	key :id
	references_many :works
	def self.create_with_omniauth(auth)
		create! do |account|
			account.provider = auth["provider"]
			account.uid = auth["uid"]
			account.screen_name = auth["info"]["nickname"]
		end
	end
end

configure do
	enable :sessions
	use OmniAuth::Builder do
		provider :twitter, ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
	end
end

helpers do
	def current_user
		@current_user ||= User.where(uid: session[:uid]).first
	end
end

before do
	pass if request.path_info =~ /^\/auth\//
	redirect to('/auth/twitter') unless current_user
end

after do
	response.body = haml env['sinatra.route'].split(' ').last.intern if response.status == 200
end

get '/auth/twitter/callback' do
	auth = request.env["omniauth.auth"]
	user = User.where(:provider => auth["provider"], :uid => auth["uid"]).first || User.create_with_omniauth(auth)
	session[:uid] = auth["uid"]
	redirect "http://#{request.env["HTTP_HOST"]}/#{user.screen_name}"
end

get '/auth/failure' do
end

get '/logout' do
	session[:uid] = nil
	redirect '/'
end

get '/' do
	'Hello omniauth-twitter!'
end

