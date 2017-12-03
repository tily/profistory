class User
	include Mongoid::Document
	include Mongoid::Timestamps
	field :screen_name, :type => String
	field :uid, :type => String
	field :provider, :type => String
	field :allow_edition_to, :type => String
	field :tilt, :type => Integer
	validates :allow_edition_to, :allow_nil => true, :inclusion => {:in => ['none', 'nnade users', 'anyone']}
	validates :tilt, :allow_nil => true, :inclusion => {:in => (0..359)}
	has_many :works
	def self.create_with_omniauth(auth)
		create! do |account|
			account.provider = auth["provider"]
			account.uid = auth["uid"]
			account.screen_name = case Settings.auth.provider
			when "twitter"
				auth["info"]["nickname"]
			when "saml"
				auth["uid"]
			end
		end
	end
end
