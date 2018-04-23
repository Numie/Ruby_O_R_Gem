require_relative 'db_connection'
require_relative 'relation'

module Searchable
  def find_by_sql(query)
    relation = ReactiveRecord::Relation.new
    relation.model_name = self
    relation.query_string = query
    relation.execute
  end

  def select(*cols)
    #create the string of select fields
    if cols.is_a?(String)
      vals = cols
    else
      vals = cols.map(&:to_s).join(", ")
    end

    relation = ReactiveRecord::Relation.new
    relation.model_name, relation.from_line, relation.joined_models, relation.select_line = self.name.constantize, self.table_name, [self.name.constantize], vals
    relation
  end

  def joins(association)
    if self.assoc_options[association]
      source_association = nil
    elsif self.through_options[association]
      source_association = self.through_options[association].source_name
      association = self.through_options[association].through_name
    else
      raise "#{association} is not a valid association of #{self.name}"
    end

    join_class_name = self.assoc_options[association].class_name
    join_table_name = join_class_name.constantize.table_name

    foreign_key = self.assoc_options[association].foreign_key
    type = self.columns.include?(foreign_key) ? :belongs_to : :has_many

    if type == :belongs_to
      joins_line = "INNER JOIN #{join_table_name} ON #{self.table_name}.#{foreign_key} = #{join_table_name}.id"
    else
      joins_line = "INNER JOIN #{join_table_name} ON #{self.table_name}.id = #{join_table_name}.#{foreign_key}"
    end

    relation = ReactiveRecord::Relation.new
    relation.model_name, relation.from_line, relation.joined_models, relation.joins_line = self.name.constantize, self.table_name, [self.name.constantize, join_class_name.constantize], joins_line
    source_association ? relation.joins(source_association) : relation
  end

  def where(params, *args)
    #create the string of where conditions
    if params.is_a?(Hash)
      vals = []
      where_line = params.map do |param, val|
        if val.is_a?(Range)
          vals += [val.first, val.last]
          "#{param} BETWEEN ? AND ?"
        elsif val.is_a?(Array)
          #create correct number of question marks
          question_marks = val.map { |c| "?" }.join(", ")
          vals += val
          "#{param} IN (#{question_marks})"
        else
          vals << val
          "#{param} = ?"
        end
      end.join(" AND ")
    elsif args
      where_line = params
      vals = args
    elsif params.is_a?(String)
      where_line = params
      vals = []
    else
      raise 'ReactiveRecord Error'
    end

    relation = ReactiveRecord::Relation.new
    relation.model_name, relation.from_line, relation.joined_models, relation.where_line, relation.where_vals = self.name.constantize, self.table_name, [self.name.constantize], where_line, vals
    relation
  end

  def order(*cols)
    if cols.is_a?(String)
      order_by_line = cols
    else
      string_cols = cols.map do |col|
        if col.is_a?(Hash)
          col.flatten(&:to_s).join(" ")
        else
          col.to_s
        end
      end
      order_by_line = string_cols.join(", ")
    end

    relation = ReactiveRecord::Relation.new
    relation.model_name, relation.from_line, relation.joined_models, relation.order_line = self.name.constantize, self.table_name, [self.name.constantize], order_by_line
    relation
  end

  def limit(n)
    relation = ReactiveRecord::Relation.new
    relation.model_name, relation.from_line, relation.joined_models, relation.limit_line = self.name.constantize, self.table_name, [self.name.constantize], n
    relation
  end
end
