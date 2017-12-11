class Tag
  def self.all
    tags = []

    # Use only models that have any records.
    # (all_tags fails if the collection itself does not exist.)
    models = []
    models << User if User.count > 0
    models << Work if Work.count > 0

    models.each do |model|
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
