# coding: utf-8
Bundler.require

class User
	include Mongoid::Document
	include Mongoid::Timestamps
	field :screen_name, :type => String
	field :uid, :type => String
	field :provider, :type => String
	has_many :works
	def self.create_with_omniauth(auth)
		create! do |account|
			account.provider = auth["provider"]
			account.uid = auth["uid"]
			account.screen_name = auth["info"]["nickname"]
		end
	end
end

class Work
	include Mongoid::Document
	include Mongoid::Timestamps
	field :title, type: String
	field :description, type: String
	field :links_text, type: String
	field :date, type: Time
	validates :title, :length => {:maximum => 35}
	validates :description, :length => {:maximum => 140}
	validates :title, :presence => true
	validates :links_text, :presence => true
	validate do |work|
		if links.flatten.any? {|link| !URI::regexp.match(link) }
			work.errors.add(:link_text, "includes invalid URL(s)")
		end
		if links.flatten.size > 50
			work.errors.add(:link_text, "includes more than 50 URLs")
		end
	end
	belongs_to :user
	def links
		links_text.gsub(/\r/, '').split(/\n{2,}/).map {|x| x.split("\n") }
	end
end

configure do
	enable :sessions
	set :session_secret, ENV['SESSION_SECRET']
	set :haml, ugly: true, escape_html: true
	set :protection, :except => :path_traversal

	use OmniAuth::Builder do
		provider :twitter, ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
	end

	uri = URI.parse(ENV['MONGOHQ_URL'])
	db = uri.path.gsub(/^\//, '')
	connection = Mongo::Connection.new(uri.host, uri.port)
	connection.db(db).authenticate(uri.user, uri.password) unless (uri.user.nil? || uri.password.nil?)
	use Rack::Session::Mongo, :connection => connection, :db => db, :expire_after => 60*60*24*7 # 1 week

	Mongoid.load!("./mongoid.yml")

	TITLE = 'nnade'.split('').join(' ')
end

helpers do
	def current_user
		@current_user ||= User.where(uid: session[:uid]).first
	end

	def title
		title = TITLE.dup
		title << " > #{params[:screen_name]}" if params[:screen_name]
		title << " > #{CGI.unescape(params[:title])}" if params[:title]
		title
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
	haml :'/'
end

get '/:screen_name/:title/edit' do
	@user = User.where(:screen_name => params[:screen_name]).first
	@work = @user.works.where(:title => CGI.unescape(params[:title])).first
	haml :'/:screen_name/:title/edit'
end

get '/:screen_name/:title' do
	@user = User.where(:screen_name => params[:screen_name]).first
	@work = @user.works.where(:title => CGI.unescape(params[:title])).first
	haml :'/:screen_name/:title'
end

get '/:screen_name.json' do
	content_type 'text/json'
	@user = User.where(:screen_name => params[:screen_name]).first
	JSON.pretty_generate JSON.parse jbuilder :'/:screen_name.json', layout: false
end

get '/:screen_name' do
	@user = User.where(:screen_name => params[:screen_name]).first
	@works = @user.works.desc(:date)
	@years = @user.works.map {|work| work.date.year }.uniq.sort.reverse
	haml :'/:screen_name'
end

post '/:screen_name' do
	@user = User.where(:screen_name => params[:screen_name]).first
	halt 403 if @user != current_user
	attributes =  {
		title: CGI.unescape(params[:title]),
		description: params[:description],
		links_text: params[:links_text],
		date: params[:date]
	}
	if params[:old_title] && (@work = current_user.works.where(:title => CGI.unescape(params[:old_title])).first)
		@work.update_attributes(attributes)
	else
		@work = current_user.works.create(attributes)
	end
	if @work.save
		redirect "http://#{request.env["HTTP_HOST"]}/#{current_user.screen_name}/#{CGI.escape(@work.title)}"
	else
		haml :'/:screen_name/:title/edit'
	end
end

__END__
@@ layout
!!! 5
%html
	%head
		%meta{charset: 'utf-8'}/
		%meta{name:"viewport",content:"width=device-width,initial-scale=1.0"}
		%title= title
		%script{src:"http://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js",type:"text/javascript"}
		%script{src:"http://cdn.embed.ly/jquery.embedly-3.1.1.min.js",type:"text/javascript"}
		%link{rel:'stylesheet',href:'http://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css'}
		:css
			a,a:hover { color:blue }
			img { max-width: 100% }
			div { word-break: break-all }
			img.favicon {
				width: 1em;
				height: 1em;
				-webkit-filter: grayscale(100%);
				filter: url("data:image/svg+xml;utf8,<svg xmlns=\'http://www.w3.org/2000/svg\'><filter id=\'grayscale\'><feColorMatrix type=\'matrix\' values=\'0.3333 0.3333 0.3333 0 0 0.3333 0.3333 0.3333 0 0 0.3333 0.3333 0.3333 0 0 0 0 0 1 0\'/></filter></svg>#grayscale");
				filter: gray;
			}
	%body
		%div.container
			%p{style:"padding-top:1em;padding-bottom:0em"}
				%strong
					%a{href:'/'}= TITLE
					- if @user
						&nbsp;>&nbsp;
						%a{href:"/#{@user.screen_name}"} #{@user.screen_name}
					- if @work
						&nbsp;>&nbsp;
						= @work.title
				%span{style:'float:right'}
					- if current_user
						%a{href:"/#{current_user.screen_name}"} my page
						&nbsp;|&nbsp;
						%a{href:'/logout'} logout
					- else
						%a{href:'/auth/twitter'} login
			%hr
			!= yield
@@ /
Create your portfolio with URLs
%h2 recent works
%ul
	- @works.each do |work|
		%li
			%a{href:"/#{work.user.screen_name}/#{CGI.escape(work.title)}"}= work.title
			by
			= work.user.screen_name
@@ /:screen_name
%h1= @user.screen_name
- if @user == current_user
	%a{href:"/#{@user.screen_name}/*/edit"} add work
	&nbsp;|&nbsp;
%a{href:"/#{@user.screen_name}.json"} get json
%div.row
	- @years.each do |year|
		%div.col-md-3
			%h2= year
			%ul
				- @works.each do |work|
					- if work.date.year == year
						%li
							%a{href:"/#{@user.screen_name}/#{CGI.escape(work.title)}",alt:work.description}= work.title
@@ /:screen_name.json
json.array!(@user.works) do |work|
	json.title work.title
	json.description work.description
	json.date work.date
	json.links work.links
end
@@ /:screen_name/:title
- if @user == current_user
	%a{href:"/#{@user.screen_name}/#{CGI.escape(@work.title)}/edit"} edit work
%p
	%h1
		= @work.title
		%small
			= @work.description
	%p= "#{@work.date.strftime('%Y-%m-%d')}"
- @work.links.each_with_index do |links, i|
	%div.row
		- links.each do |link|
			%div.col-md-3{style:'padding-bottom:10px'}
				%img.favicon{src:'/favicon.ico'}
				%a{href:link,target:'_blank'}= link
	- if i != @work.links.size - 1
		%hr
:javascript
	var width = $('div.row div').width()
	$('div.row a').each(function(i, e) {
		$(e).embedly({
			endpoint: 'extract',
			query: { maxwidth: width },
			key: '19cf7d11f0d14c47b0625df7070823ad',
			done: function(result) {
				console.log(result)
				if(result[0].type == 'image') {
					$(e).prev().remove()
					$(e).html($('<img src="' + result[0].url + '">'))
			 	} else if(result[0].media && result[0].media.html) {
					$(e).prev().remove()
					$(e).html(result[0].media.html)
				} else {
					if(result[0].favicon_url) {
						$(e).prev().attr('src', result[0].favicon_url)
					}
					if(result[0].title) {
						$(e).html(result[0].title)
					}
					$(e).after('<br />', result[0].description)
				}
			}	
		})
	})
@@ /:screen_name/:title/edit
- if @work && !@work.errors.empty?
	.alert.alert-danger
		%ul
			- @work.errors.each do |field, message|
				%li= "#{field} #{message}"
%form.form-horizontal{role:'form',method:'POST',action:"/#{@user.screen_name}"}
	- if @work
		%input.form-control{name:'old_title',type:'hidden',value:@work.title}
	%div.form-group
		%label.col-sm-2.control-label{for:'date'} date
		%div.col-sm-2
			%input.form-control{name:'date',type:'text',value:(@work.try(:date)||Time.now).strftime('%Y/%m/%d')}
	%div.form-group
		%label.col-sm-2.control-label{for:'title'} title
		%div.col-sm-5
			%input.form-control{name:'title',type:'text',value:@work.try(:title)}
	%div.form-group
		%label.col-sm-2.control-label{for:'description'} description
		%div.col-sm-10
			%input.form-control{name:'description',type:'text',value:@work.try(:description)}
	%div.form-group
		%label.col-sm-2.control-label{for:'links'} links
		%div.col-sm-10
			%span.help-block one url per one line, insert empty lines to group your links
			%textarea.form-control{name:'links_text',rows:'25',style:'height: 1000'}
				= @work.try(:links_text)
	%div.form-group
		%div.col-sm-offset-2.col-sm-10
			%button{type:'submit',class:'btn btn-default'}= @work ? 'update' : 'add'
