class Tag
  def self.all
    tags = []
    [User, Work].each do |model|
      model.all_tags.each do |model_tag|
        if tag = tags.find {|tag| tag[:name] == model_tag[:name] }
          tag[:count] += model_tag[:count]
        else
          tags << model_tag
        end
      end
    end
    tags
  end
end
