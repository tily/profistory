# coding: utf-8
Bundler.require
require_relative './models/user'
require_relative './models/work'

configure do
	register Config
	enable :sessions
	set :session_secret, Settings.session.secret
	set :haml, ugly: true, escape_html: true
	set :protection, :except => :path_traversal
	use OmniAuth::Builder do
		provider :twitter, Settings.twitter.consumer_key, Settings.twitter.consumer_secret
	end
	use Rack::Session::Moneta, store: Moneta.new(:Mongo, host: "db")
	Mongoid.load!("config/mongoid.yml")
end

helpers do
	def current_user
		@current_user ||= User.where(uid: session[:uid]).first
	end

	def title
		title = Settings.title.dup
		title << " > #{params[:screen_name]}" if params[:screen_name]
		title << " > #{CGI.unescape(params[:title])}" if params[:title]
		title
	end

	def allowed_to_edit?(user)
		case user.allow_edition_to
		when 'anyone'; true
		when 'users'; current_user
		else; current_user == user
		end
	end
end

before do
	pass if request.path_info =~ /^\/auth\//
end

after do
end

get '/auth/twitter/callback' do
	auth = request.env["omniauth.auth"]
	User.where(:provider => auth["provider"], :uid => auth["uid"]).first || User.create_with_omniauth(auth)
	session[:uid] = auth["uid"]
	redirect "http://#{request.env["HTTP_HOST"]}/#{current_user.screen_name}"
end

get '/auth/failure' do
end

get '/logout' do
	session[:uid] = nil
	redirect '/'
end

get '/' do
	@works = Work.desc(:created_at).limit(20)
	haml :index
end

get '/:screen_name/settings/edit' do
	haml :edit_user
end

post '/:screen_name/settings' do
	current_user.update_attributes!(
		allow_edition_to: CGI.unescape(params[:allow_edition_to]),
		tilt: params[:tilt]
	)
	redirect "http://#{request.env["HTTP_HOST"]}/#{current_user.screen_name}"
end

get '/:screen_name/:title/edit' do
	@user = User.where(:screen_name => params[:screen_name]).first
	@work = @user.works.where(:title => CGI.unescape(params[:title])).first
	haml :edit_work
end

get '/:screen_name/:title' do
	@user = User.where(:screen_name => params[:screen_name]).first
	@work = @user.works.where(:title => CGI.unescape(params[:title])).first
	haml :work
end

get '/:screen_name.json' do
	content_type 'text/json'
	if params[:screen_name] == '*'
		@works = Work.desc(:date)
		JSON.pretty_generate JSON.parse jbuilder :user, layout: false
	else
		@works = User.where(:screen_name => params[:screen_name]).first.works.desc(:date)
	end
	JSON.pretty_generate JSON.parse jbuilder :user, layout: false
end

get '/:screen_name' do
	@user = User.where(:screen_name => params[:screen_name]).first
	@works = @user.works.desc(:date)
	@years = @user.works.map {|work| work.date.year }.uniq.sort.reverse
	haml :user
end

post '/:screen_name' do
	@user = User.where(:screen_name => params[:screen_name]).first
	halt 403 if !allowed_to_edit?(@user)
	attributes =  {
		title: CGI.unescape(params[:title]),
		description: params[:description],
		links_text: params[:links_text],
		date: params[:date]
	}
	if params[:old_title] && (@work = @user.works.where(:title => CGI.unescape(params[:old_title])).first)
		@work.update_attributes(attributes)
	else
		@work = @user.works.create(attributes)
	end
	if @work.save
		redirect "http://#{request.env["HTTP_HOST"]}/#{@user.screen_name}/#{CGI.escape(@work.title)}"
	else
		haml :work
	end
end
