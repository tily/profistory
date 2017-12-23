json.array!(@users) do |user|
  json.name        user.name
  json.screen_name user.screen_name
  json.tags        user.tags
  json.works do
    json.array!(user.works) do |work|
      json.title       work.title
      json.description work.description
      json.members     work.users.map {|user| user.name }
      json.tags        work.tags
      json.links       work.links
    end
  end
end
