json.array!(@tags) do |tag|
  json.name tag[:name]
  json.count tag[:count]
end
