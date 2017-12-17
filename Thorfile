require 'open-uri'
Bundler.require
require 'faker/japanese'
require 'romaji'
require_relative './core'

class Default < Thor
  desc 'cleanup_db', 'cleanup database'
  def cleanup_db
    ::Mongoid.purge!
    ::Mongoid::Clients.default.database.drop
  end

  desc 'load_random_data', 'load random data'
  def load_random_data
    doc = Nokogiri::HTML(open("https://pinboard.in/u:youpy").read)
    tags = doc.search('#tag_cloud a.tag').map {|x| x.text }

    users = []
    1.upto(200) do |i|
      first_name = Faker::Japanese::Name.first_name
      last_name = Faker::Japanese::Name.last_name
      uid = [
        Romaji.kana2romaji(first_name.yomi),
        Romaji.kana2romaji(last_name.yomi)
      ].join('.') + "@gmail.com"
      users << User.create!(
        uid: uid,
        provider: "saml",
        screen_name: "#{last_name} #{first_name}",
        name: uid,
        tags: [tags.sample, tags.sample, tags.sample],
      )
    end

    url = "https://raw.githubusercontent.com/tily/domoraen/master/data/tools.json"
    items = JSON.parse(open(url).read)['originals']
    1.upto(200) do |i|
      Work.create!(
        title: items.pop,
        date: Random.rand(Time.parse("1983/09/27")..Time.parse("2017/12/15")),
        links_text: [
          "http://www.google.com",
          "http://www.google.com",
        ].join("\n"),
        tags: [tags.sample, tags.sample, tags.sample],
        users: [users.sample, users.sample, users.sample],
      )
    end
  end
end
