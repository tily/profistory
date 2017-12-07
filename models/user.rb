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
      names = extract_names_from_omniauth(auth)
      account.name = names[:name]
      account.screen_name = names[:screen_name]
    end
  end

  def update_with_omniauth(auth)
    names = extract_names_from_omniauth(auth)
    update_attributes!(
      name: names[:name],
      screen_name: names[:screen_name],
    )
  end

  def extract_names_from_omniauth(auth)
    case Settings.auth.provider
    when "twitter"
      name = auth.info.nickname
      screen_name = auth.info.nickname
    when "saml"
      name = auth.uid
      raw_info = auth.extra.raw_info
      last_name = raw_info["User.LastName"]
      first_name = raw_info["User.FirstName"]
      screen_name = [last_name, first_name].join(" ")
    end
    return {name: name, screen_name: screen_name}
  end
end
