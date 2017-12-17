source 'https://rubygems.org'
gem 'sinatra'
gem 'sinatra-contrib', require: ['sinatra/namespace', 'sinatra/respond_with']
gem 'omniauth-twitter'
gem 'ruby-saml',
  git:    'https://github.com/tily/ruby-saml.git',
  branch: 'fix/ensure_rails_responds_to_logger',
  ref:    '53cae0293498380f509f7534bf32130f6b6677cd'
gem 'omniauth-saml'
gem 'mongo'
gem 'mongoid'
# use tvarley's for https://github.com/hashdog/mongoid-simple-tags/pull/23
gem 'mongoid-simple-tags',
  git: 'https://github.com/tvarley/mongoid-simple-tags',
  branch: 'master',
  ref: '0d8503d60a12e6a01b96c29ddfa945620ae21935'
gem 'moneta', require: 'rack/session/moneta'
gem 'haml'
gem 'tilt-jbuilder', require: 'sinatra/jbuilder'
gem 'config',
  git: 'https://github.com/tily/config.git',
  branch: 'fix/padrino_should_respond_to_env_and_root',
  ref: 'cc22254bad27e8779d3edbdeef3899a7c033cb85'
gem 'kaminari-mongoid'
gem 'kaminari-sinatra'
gem 'i18n', require: ['i18n', 'i18n/backend/fallbacks']
gem 'rack-contrib'
gem 'thor'

group :development do
	gem 'shotgun'
  gem 'faker-japanese'
  gem 'romaji'
end
