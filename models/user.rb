class User
	include Mongoid::Document
	include Mongoid::Timestamps
	field :uid, :type => String
	field :name, :type => String
	field :screen_name, :type => String
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
			case Settings.auth.provider
			when "twitter"
				account.name = auth.info.nickname
				account.screen_name = auth.info.nickname
			when "saml"
				account.name = auth.uid
				raw_info = auth.extra.raw_info
				last_name = raw_info["User.LastName"]
				first_name = raw_info["User.FirstName"]
				account.screen_name = [last_name, first_name].join(" ")
			end
		end
	end
end
