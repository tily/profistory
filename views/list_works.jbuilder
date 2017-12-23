json.works do
  json.array!(@works) do |work|
    json.title       work.title
    json.date        work.date
    json.description work.description
    json.members     work.users.map {|user| user.name }
    json.tags        work.tags
    json.links       work.links
  end
end
