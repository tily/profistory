class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Document::Taggable
  field :uid, :type => String
  field :name, :type => String
  field :screen_name, :type => String
  field :provider, :type => String
  has_and_belongs_to_many :works
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
    names = self.class.extract_names_from_omniauth(auth)
    update_attributes!(
      name: names[:name],
      screen_name: names[:screen_name],
    )
  end

  def self.extract_names_from_omniauth(auth)
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
