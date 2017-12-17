json.title @work.title
json.description @work.description
json.members @work.users.map {|user| user.name }
json.date @work.date
json.links @work.links
json.tags @work.tags
