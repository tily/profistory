Bundler.require
require_relative './config/boot'
require_relative './models/user'
require_relative './models/work'
require_relative './models/tag'

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

  def allowed_to_edit?(work, user)
    work.users.find(user) rescue nil
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
  @tags = Tag.all
  haml :list_all
end

namespace '/works' do
  get '/:title/edit' do
    @work = Work.where(:title => CGI.unescape(params[:title])).first
    haml :edit_work
  end

  get '/:title' do
    @work = Work.where(:title => CGI.unescape(params[:title])).first
    haml :show_work
  end

  post do
    attributes =  {
      title: CGI.unescape(params[:title]),
      tag_list: params[:tags],
      description: params[:description],
      links_text: params[:links_text],
      date: params[:date]
    }
    if params[:old_title] && (@work = current_user.works.where(:title => CGI.unescape(params[:old_title])).first)
      if !allowed_to_edit?(@work, current_user)
        halt 403
      end
      @work.update_attributes(attributes)
    else
      @work = current_user.works.create(attributes)
    end
    if @work.save
      redirect to("works/#{@work.title_escaped}")
    else
      haml :edit_work
    end
  end

  post '/:title/join' do
    @work = Work.where(:title => CGI.unescape(params[:title])).first
    @work.users.push(current_user)
    redirect to("works/#{@work.title_escaped}")
  end

  post '/:title/leave' do
    @work = Work.where(:title => CGI.unescape(params[:title])).first
    @work.users.delete(current_user)
    redirect to("works/#{@work.title_escaped}")
  end

  get do
    @works = Work.desc(:date)
    @years = @works.map {|work| work.date.year }.uniq.sort.reverse
    haml :list_works
  end
end

namespace '/users' do
  get '/:user_name.json' do
    content_type 'text/json'
    if params[:user_name] == '*'
      @works = Work.desc(:date)
      JSON.pretty_generate JSON.parse jbuilder :show_user, layout: false
    else
      @works = User.where(:name => params[:user_name]).first.works.desc(:date)
    end
    JSON.pretty_generate JSON.parse jbuilder :show_user, layout: false
  end

  get '/:user_name' do
    @user = User.where(:name => params[:user_name]).first
    @works = @user.works.desc(:date)
    @years = @user.works.map {|work| work.date.year }.uniq.sort.reverse
    haml :show_user
  end

  post '/:user_name' do
    @user = User.where(:name => params[:user_name]).first
    @user.update_attributes!(
      tag_list: params[:tags]
    )
    redirect to("users/#{params[:user_name]}")
  end

  get do
    @users = User.page(params[:page])
    haml :list_users
  end
end

namespace '/tags' do
  get '/:name' do
    @users = User.tagged_with(params[:name])
    @works = Work.tagged_with(params[:name])
    haml :show_tag
  end
end
