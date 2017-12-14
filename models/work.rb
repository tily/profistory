class Work
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Document::Taggable
  field :title, type: String
  field :description, type: String
  field :links_text, type: String
  field :date, type: Time
  validates :title, :length => {:maximum => 35}, uniqueness: true
  validates :description, :length => {:maximum => 140}
  validates :title, :presence => true
  validates :links_text, :presence => true
  validate do |work|
    if links.flatten.any? {|link| !URI::regexp.match(link) }
      work.errors.add(:link_text, "includes invalid URL(s)")
    end
    if links.flatten.size > 100
      work.errors.add(:link_text, "includes more than 100 URLs")
    end
  end
  has_and_belongs_to_many :users
  def links
    links_text.gsub(/\r/, '').split(/\n{2,}/).map {|x| x.split("\n") }
  end

  def title_escaped
    CGI.escape(self.title)
  end
end
