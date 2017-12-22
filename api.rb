require_relative './core'

class Profistory
  class API < Core
    register Sinatra::Namespace
    register Kaminari::Helpers::SinatraHelpers

    respond_to :json

    def api_key
      request.env["HTTP_X_PROFISTORY_API_KEY"]
    end

    def current_user
      @current_user ||= User.where(api_key: api_key).first
    end

    before do
      halt 401 if api_key.nil? || current_user.nil?
      request.body.rewind
      json_params = JSON.parse(request.body.read)
      json_params.each do |k, v|
        params[k] = v
      end
    end

    namespace '/works' do
      get('.json')              { list_works  }
      get('/:title.json')       { show_work   }
      put('/:title.json')       { create_work }
      put('/:title/join.json')  { join_work   }
      put('/:title/leave.json') { leave_work  }
    end

    namespace '/users' do
      get('.json')            { list_users }
      get('/:user_name.json') { show_user  }
    end

    namespace '/tags' do
      get('.json')       { list_tags }
      get('/:name.json') { show_tag  }
    end
  end
end
