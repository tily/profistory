Bundler.require
require_relative './config/boot'
require_relative './models/user'
require_relative './models/work'

helpers do
  def current_user
    @current_user ||= User.where(uid: session[:uid]).first
  end

  def title
    title = Settings.title.dup
    title << " > #{params[:user_name]}" if params[:user_name]
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

get '/logout' do
  session[:uid] = nil
  redirect to('/')
end

get '/' do
  @users = User.desc(:created_at).limit(20)
  @works = Work.desc(:created_at).limit(20)
  haml :index
end

namespace '/settings' do
  get '/edit' do
    haml :edit_user
  end

  post do
    current_user.update_attributes!(
      allow_edition_to: CGI.unescape(params[:allow_edition_to]),
      tilt: params[:tilt],
      tag_list: params[:tags]
    )
    redirect to("users/#{current_user.name}")
  end
end

namespace '/works' do
  get '/:title/edit' do
    @work = Work.where(:title => CGI.unescape(params[:title])).first
    haml :edit_work
  end

  get '/:title' do
    @work = Work.where(:title => CGI.unescape(params[:title])).first
    haml :work
  end

  post '/' do
    attributes =  {
      title: CGI.unescape(params[:title]),
      tag_list: params[:tags],
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
      redirect to("works/#{@work.title}")
    else
      haml :work
    end
  end
end

namespace '/users' do
  get '/:user_name.json' do
    content_type 'text/json'
    if params[:user_name] == '*'
      @works = Work.desc(:date)
      JSON.pretty_generate JSON.parse jbuilder :user, layout: false
    else
      @works = User.where(:name => params[:user_name]).first.works.desc(:date)
    end
    JSON.pretty_generate JSON.parse jbuilder :user, layout: false
  end

  get '/:user_name' do
    @user = User.where(:name => params[:user_name]).first
    @works = @user.works.desc(:date)
    @years = @user.works.map {|work| work.date.year }.uniq.sort.reverse
    haml :user
  end
end
