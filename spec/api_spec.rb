require_relative 'spec_helper'

describe Profistory::API do
  let(:last_response_json) { JSON.parse(last_response.body) }

  def create_api_user
    User.create!(
      uid:         SecureRandom.hex(16),
      name:        SecureRandom.hex(16),
      screen_name: SecureRandom.hex(16),
      api_key:     SecureRandom.hex(16)
    )
  end

  context 'Authorization' do
    it 'fails if no API key is provided' do
      get '/works.json'
      expect(last_response.status).to eq(401)
      expect(last_response_json['error']['message']) == 'Unauthorized'
    end

    it 'fails if an invalid API key is provided' do
      header 'X-Profistory-API-Key', 'Wrong API key'
      get '/works.json'
      expect(last_response.status).to eq(401)
      expect(last_response_json['error']['message']) == 'Unauthorized'
    end

    it 'passes if a valid API key is provided' do
      header 'X-Profistory-API-Key', create_api_user.api_key
      get '/works.json'
      expect(last_response.status).to eq(200)
      expect(last_response_json['works']).to be_a(Array)
    end
  end

  context 'Operations' do
    before do
      @user = create_api_user
      header 'X-Profistory-API-Key', user.api_key
    end

    let(:user) { @user }

    context 'Works' do
      context 'GET /works.json' do
        it 'gets some works if there are any works' do
          get '/works.json'
          expect(last_response.status).to eq(200)
        end

        it 'gets no works if there are no works' do
          Work.delete_all
          get '/works.json'
          expect(last_response.status).to eq(200)
          expect(last_response_json['works']).to eq([])
        end
      end

      context 'GET /works/:title.json' do
      end

      context 'PUT /works/:title.json' do
      end

      context 'PUT /works/:title/join.json' do
      end

      context 'PUT /works/:title/leave.json' do
      end
    end

    context 'Users' do
      context 'GET /users.json' do
      end

      context 'GET /users/:user_name.json' do
      end

      context 'PUT /users/:user_name.json' do
      end
    end

    context 'Tags' do
      context 'GET /tags.json' do
      end

      context 'GET /tags/:name.json' do
      end
    end
  end
end
