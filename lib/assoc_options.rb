require 'active_support/inflector'

class AssocOptions
  attr_accessor :type, :foreign_key, :class_name, :primary_key, :through_name, :source_name

  def model_class
    self.class_name.constantize
  end

  def table_name
    #use predefined custom 'table-name' method
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})

    #set defaults if values are not present
    defaults = {
      :type => :belongs_to,
      :class_name => name.to_s.capitalize.singularize.camelcase,
      :primary_key => :id,
      :foreign_key => "#{name.to_s.singularize.underscore}_id".to_sym
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end

  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})

    #set defaults if values are not present
    defaults = {
      :type => :has_many,
      :class_name => name.to_s.capitalize.singularize.camelcase,
      :primary_key => :id,
      :foreign_key => "#{self_class_name.to_s.singularize.underscore}_id".to_sym
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end

  end
end

class ThroughOptions < AssocOptions
  def initialize(name, through_name, source_name)
    @through_name = through_name
    @source_name = source_name
  end
end
