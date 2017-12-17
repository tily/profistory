Bundler.require
require_relative './models/user'
require_relative './models/work'
require_relative './models/tag'

class Profistory
  class Core < Sinatra::Base
    register Config
    Mongoid.load!("config/mongoid.yml")

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
  
    def gravatar_icon(user, size=nil)
      url = "//gravatar.com/avatar/#{Digest::MD5.hexdigest(user.uid)}"
      url += "?size=#{size}" if size
      url
    end

    def create_work
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

    def show_work
      @work = Work.where(:title => CGI.unescape(params[:title])).first
      haml :show_work
    end

    def join_work
      @work = Work.where(:title => CGI.unescape(params[:title])).first
      @work.users.push(current_user)
      redirect to("works/#{@work.title_escaped}")
    end

    def leave_work
      @work = Work.where(:title => CGI.unescape(params[:title])).first
      @work.users.delete(current_user)
      redirect to("works/#{@work.title_escaped}")
    end

    def list_works
      @works = Work.desc(:date)
      @years = @works.map {|work| work.date.year }.uniq.sort.reverse
      haml :list_works
    end

    def list_users
      @users = User.order_by(:uid.asc)
      @atoz = @users.map {|user| user.name[0].upcase }.uniq.sort
      haml :list_users
    end

    def update_user
      @user = User.where(:name => params[:user_name]).first
      @user.update_attributes!(
        tag_list: params[:tags]
      )
      redirect to("users/#{params[:user_name]}")
    end

    def show_user
      @user = User.where(:name => params[:user_name]).first
      @works = @user.works.desc(:date)
      @years = @user.works.map {|work| work.date.year }.uniq.sort.reverse
      haml :show_user
    end

    def list_tags
      @tags = Tag.all
      @max_count = @tags.map {|tag| tag[:count] }.max
      @min_count = @tags.map {|tag| tag[:count] }.min @tags.each do |tag|
        weight = tag[:count].to_f / (@max_count - @min_count)
        tag[:size] = (weight * 5).round
      end
      haml :list_tags
    end

    def show_tag
      @users = User.tagged_with(params[:name])
      @works = Work.tagged_with(params[:name])
      haml :show_tag
    end
  end
end
