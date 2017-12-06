json.array!(@works) do |work|
  json.title work.title
  json.description work.description
  json.date work.date
  json.links work.links
end
