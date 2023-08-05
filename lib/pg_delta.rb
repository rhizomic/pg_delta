# frozen_string_literal: true

require "pg_query"

require_relative "pg_delta/version"

module PgDelta
  class Error < StandardError; end

  # Parses the provided queries and returns a PgQuery statement for each query.
  # Returns an empty list if the queries cannot be parsed.
  #
  # @param queries [String] The queries
  # @return [Array<PgQuery::Node>] The info about the parsed query
  def self.split_statements(queries)
    parsed_query = PgQuery.parse queries
    parsed_query.tree.stmts.map(&:stmt)
  rescue
    []
  end

  # Parses a single query and its corresponding PgQuery statement.
  # Returns an empty hash if the query cannot be parsed.
  #
  # @param query [String] The query
  # @return [Hash] The info about the parsed query
  def self.parse_query(query)
    parsed_query = PgQuery.parse query
    statement = parsed_query.tree.stmts.first.stmt
    parse_statement statement
  rescue
    {}
  end

  # Returns information about the supplied statement.
  #
  # @param statement [PgQuery::Node] The statement
  # @return [Hash] The info about the statement
  def self.parse_statement(statement)
    case statement.node
    when :alter_domain_stmt
      alter_domain statement.alter_domain_stmt
    when :alter_enum_stmt
      alter_enum statement.alter_enum_stmt
    when :alter_table_stmt
      case statement.alter_table_stmt.cmds[0].alter_table_cmd.subtype
      when :AT_SetNotNull
        alter_table_set_not_null statement.alter_table_stmt
      when :AT_AddColumn
        alter_table_add_column statement.alter_table_stmt
      when :AT_DropColumn
        alter_table_drop_column statement.alter_table_stmt
      when :AT_AddConstraint
        alter_table_add_constraint statement.alter_table_stmt
      when :AT_DropConstraint
        alter_table_drop_constraint statement.alter_table_stmt
      when :AT_ValidateConstraint
        alter_table_validate_constraint statement.alter_table_stmt
      when :AT_DropNotNull
        alter_table_drop_not_null statement.alter_table_stmt
      when :AT_ColumnDefault
        alter_table_column_default statement.alter_table_stmt
      when :AT_AlterColumnType
        alter_table_alter_column_type statement.alter_table_stmt
      when :AT_DisableTrig
        alter_table_disable_trigger statement.alter_table_stmt
      when :AT_SetRelOptions
        # Don't return anything for now.
        {}
      when :AT_EnableTrig
        alter_table_enable_trigger statement.alter_table_stmt
      else
        unknown statement
      end
    when :create_domain_stmt
      create_domain statement.create_domain_stmt
    when :create_enum_stmt
      create_enum statement.create_enum_stmt
    when :create_extension_stmt
      # Don't return anything for now.
      {}
    when :create_function_stmt
      create_function statement.create_function_stmt
    when :create_stmt
      create_table statement.create_stmt
    when :create_table_as_stmt
      create_table_as statement.create_table_as_stmt
    when :create_trig_stmt
      create_trigger statement.create_trig_stmt
    when :delete_stmt
      delete statement.delete_stmt
    when :drop_stmt
      case statement.drop_stmt.remove_type
      when :OBJECT_INDEX
        drop_index statement.drop_stmt
      when :OBJECT_TABLE
        drop_table statement.drop_stmt
      when :OBJECT_TYPE
        drop_type statement.drop_stmt
      when :OBJECT_TRIGGER
        drop_trigger statement.drop_stmt
      when :OBJECT_FUNCTION
        drop_function statement.drop_stmt
      when :OBJECT_VIEW
        drop_view statement.drop_stmt
      when :OBJECT_DOMAIN
        drop_domain statement.drop_stmt
      when :OBJECT_MATVIEW
        drop_materialized_view statement.drop_stmt
      else
        unknown statement
      end
    when :index_stmt
      create_index statement.index_stmt
    when :insert_stmt
      insert statement.insert_stmt
    when :rename_stmt
      case statement.rename_stmt.rename_type
      when :OBJECT_TABCONSTRAINT
        rename_constraint statement.rename_stmt
      when :OBJECT_TABLE
        rename_table statement.rename_stmt
      when :OBJECT_COLUMN
        rename_column statement.rename_stmt
      when :OBJECT_FUNCTION
        rename_function statement.rename_stmt
      when :OBJECT_TRIGGER
        rename_trigger statement.rename_stmt
      when :OBJECT_INDEX
        rename_index statement.rename_stmt
      when :OBJECT_TYPE
        rename_type statement.rename_stmt
      else
        unknown statement
      end
    when :truncate_stmt
      truncate statement.truncate_stmt
    when :update_stmt
      update statement.update_stmt
    when :view_stmt
      view statement.view_stmt
    when :select_stmt
      # TODO: This is tricky, because this could call a function which might
      # alter the schema.
      # Don't return anything for now.
      {}
    when :create_seq_stmt
      # Don't return anything for now.
      {}
    when :create_stats_stmt
      # Don't return anything for now.
      {}
    when :define_stmt
      # Don't return anything for now.
      {}
    when :alter_seq_stmt
      # Don't return anything for now.
      {}
    when :comment_stmt
      # Don't return anything for now.
      {}
    when :lock_stmt
      # Don't return anything for now.
      {}
    when :variable_set_stmt
      # Don't return anything for now.
      {}
    when :transaction_stmt
      # "begin;" and "commit;" are parsed as :transaction_stmt.
      # Don't return anything for now.
      {}
    when :do_stmt
      # Don't return anything for now.
      {}
    else
      unknown statement
    end
  end

  # Column mutations

  def self.alter_table_add_column(statement)
    {
      mutation: :alter_table_add_column,
      type: :column,
      details: {
        table_name: statement.relation.relname,
        column_name: statement.cmds.first.alter_table_cmd.def.column_def.colname,
        column_type: statement.cmds.first.alter_table_cmd.def.column_def.type_name.names.last.string.sval
      }
    }
  end

  def self.alter_table_column_default(statement)
    # PgQuery sadly doesn't differentiate between adding and dropping
    # column defaults at the node level, so we have to do it here.
    if statement.cmds.first.alter_table_cmd.def
      # The query is setting a default.
      {
        mutation: :alter_table_set_column_default,
        type: :column,
        details: {
          table_name: statement.relation.relname,
          column_name: statement.cmds.first.alter_table_cmd.name
        }
      }
    else
      {
        mutation: :alter_table_drop_column_default,
        type: :column,
        details: {
          table_name: statement.relation.relname,
          column_name: statement.cmds.first.alter_table_cmd.name
        }
      }
    end
  end

  def self.alter_table_drop_column(statement)
    {
      mutation: :alter_table_drop_column,
      type: :column,
      details: {
        table_name: statement.relation.relname,
        column_name: statement.cmds.first.alter_table_cmd.name
      }
    }
  end

  def self.alter_table_drop_not_null(statement)
    {
      mutation: :alter_table_drop_not_null,
      type: :column,
      details: {
        table_name: statement.relation.relname,
        column_name: statement.cmds.first.alter_table_cmd.name
      }
    }
  end

  def self.alter_table_set_not_null(statement)
    {
      mutation: :alter_table_set_not_null,
      type: :column,
      details: {
        table_name: statement.relation.relname,
        column_name: statement.cmds.first.alter_table_cmd.name
      }
    }
  end

  def self.rename_column(statement)
    {
      mutation: :alter_table_rename_column,
      type: :column,
      details: {
        table_name: statement.relation.relname,
        old_column_name: statement.subname,
        new_column_name: statement.newname
      }
    }
  end

  # Domain mutations

  def self.alter_domain(statement)
    {
      mutation: :alter_domain,
      type: :domain,
      details: {
        domain_name: statement.type_name.first.string.sval
      }
    }
  end

  def self.create_domain(statement)
    {
      mutation: :create_domain,
      type: :domain,
      details: {
        domain_name: statement.domainname.first.string.sval
      }
    }
  end

  def self.drop_domain(statement)
    {
      mutation: :drop_domain,
      type: :domain,
      details: {
        domain_name: statement.objects.first.type_name.names.first.string.sval
      }
    }
  end

  # Enum mutations

  def self.alter_enum(statement)
    {
      mutation: :alter_enum,
      type: :enum,
      details: {
        enum_name: statement.type_name.first.string.sval
      }
    }
  end

  def self.create_enum(statement)
    {
      mutation: :create_enum,
      type: :enum,
      details: {
        enum_name: statement.type_name.first.string.sval
      }
    }
  end

  # Function mutations

  def self.create_function(statement)
    {
      mutation: :create_function,
      type: :function,
      details: {
        function_name: statement.funcname.first.string.sval
      }
    }
  end

  def self.drop_function(statement)
    {
      mutation: :drop_function,
      type: :function,
      details: {
        function_name: statement.objects.first.object_with_args.objname.first.string.sval
      }
    }
  end

  def self.rename_function(statement)
    {
      mutation: :rename_function,
      type: :function,
      details: {
        old_function_name: statement.object.object_with_args.objname.first.string.sval,
        new_function_name: statement.newname
      }
    }
  end

  # Table mutations

  def self.create_table(statement)
    {
      mutation: :create_table,
      type: :table,
      details: {
        table_name: statement.relation.relname
      }
    }
  end

  def self.create_table_as(statement)
    {
      mutation: :create_table_as,
      type: :table,
      details: {
        table_name: statement.into.rel.relname
      }
    }
  end

  def self.drop_table(statement)
    {
      mutation: :drop_table,
      type: :table,
      details: {
        table_name: statement.objects.first.list.items.first.string.sval
      }
    }
  end

  def self.rename_table(statement)
    {
      mutation: :rename_table,
      type: :table,
      details: {
        old_table_name: statement.relation.relname,
        new_table_name: statement.newname
      }
    }
  end

  def self.truncate(statement)
    {
      mutation: :truncate_table,
      type: :table,
      details: {
        table_names: statement.relations.map(&:range_var).map(&:relname)
      }
    }
  end

  # Trigger mutations

  def self.create_trigger(statement)
    {
      mutation: :create_trigger,
      type: :trigger,
      details: {
        trigger_name: statement.trigname,
        table_name: statement.relation.relname
      }
    }
  end

  def self.drop_trigger(statement)
    items = statement.objects.first.list.items
    {
      mutation: :drop_trigger,
      type: :trigger,
      details: {
        trigger_name: items.last.string.sval,
        table_name: items.first.string.sval
      }
    }
  end

  def self.alter_table_disable_trigger(statement)
    {
      mutation: :disable_trigger,
      type: :trigger,
      details: {
        table_name: statement.relation.relname,
        trigger_name: statement.cmds.first.alter_table_cmd.name
      }
    }
  end

  def self.alter_table_enable_trigger(statement)
    {
      mutation: :enable_trigger,
      type: :trigger,
      details: {
        table_name: statement.relation.relname,
        trigger_name: statement.cmds.first.alter_table_cmd.name
      }
    }
  end

  def self.rename_trigger(statement)
    {
      mutation: :rename_trigger,
      type: :trigger,
      details: {
        table_name: statement.relation.relname,
        old_trigger_name: statement.subname,
        new_trigger_name: statement.newname
      }
    }
  end

  # Data mutations

  def self.delete(statement)
    {
      mutation: :delete_data,
      type: :data,
      details: {
        table_name: statement.relation.relname
      }
    }
  end

  def self.insert(statement)
    {
      mutation: :insert_data,
      type: :data,
      details: {
        table_name: statement.relation.relname
      }
    }
  end

  def self.update(statement)
    {
      mutation: :update_data,
      type: :data,
      details: {
        table_name: statement.relation.relname,
        column_names: statement.target_list.map(&:res_target).map(&:name)
      }
    }
  end

  # Index mutations

  def self.create_index(statement)
    {
      mutation: :create_index,
      type: :index,
      details: {
        table_name: statement.relation.relname,
        column_names: statement.index_params.map(&:index_elem).map(&:name)
      }
    }
  end

  def self.drop_index(statement)
    {
      mutation: :drop_index,
      type: :index,
      details: {
        index_name: statement.objects.first.list.items.first.string.sval
      }
    }
  end

  def self.rename_index(statement)
    {
      mutation: :rename_index,
      type: :index,
      details: {
        old_index_name: statement.relation.relname,
        new_index_name: statement.newname
      }
    }
  end

  # Type mutations
  #
  def self.alter_table_alter_column_type(statement)
    {
      mutation: :alter_table_alter_column_type,
      type: :column,
      details: {
        table_name: statement.relation.relname,
        column_name: statement.cmds.first.alter_table_cmd.name,
        new_type_name: statement.cmds.first.alter_table_cmd.def.column_def.type_name.names.last.string.sval
      }
    }
  end

  def self.drop_type(statement)
    {
      mutation: :drop_type,
      type: :type,
      details: {
        type_name: statement.objects.first.type_name.names.first.string.sval
      }
    }
  end

  def self.rename_type(statement)
    {
      mutation: :rename_type,
      type: :type,
      details: {
        old_type_name: statement.object.list.items.first.string.sval,
        new_type_name: statement.newname
      }
    }
  end

  # View mutations

  def self.view(statement)
    {
      mutation: :create_view,
      type: :view,
      details: {
        view_name: statement.view.relname
      }
    }
  end

  def self.drop_materialized_view(statement)
    {
      mutation: :drop_materialized_view,
      type: :view,
      details: {
        view_name: statement.objects.first.list.items.first.string.sval
      }
    }
  end

  def self.drop_view(statement)
    {
      mutation: :drop_view,
      type: :view,
      details: {
        view_name: statement.objects.first.list.items.first.string.sval
      }
    }
  end

  # Constraint mutations

  def self.alter_table_add_constraint(statement)
    {
      mutation: :alter_table_add_constraint,
      type: :constraint,
      details: {
        table_name: statement.relation.relname,
        constraint_name: statement.cmds.first.alter_table_cmd.def.constraint.conname
      }
    }
  end

  def self.alter_table_drop_constraint(statement)
    {
      mutation: :alter_table_drop_constraint,
      type: :constraint,
      details: {
        table_name: statement.relation.relname,
        constraint_name: statement.cmds.first.alter_table_cmd.name
      }
    }
  end

  def self.alter_table_validate_constraint(statement)
    {
      mutation: :alter_table_validate_constraint,
      type: :constraint,
      details: {
        table_name: statement.relation.relname,
        constraint_name: statement.cmds.first.alter_table_cmd.name
      }
    }
  end

  def self.rename_constraint(statement)
    {
      mutation: :alter_table_rename_constraint,
      type: :constraint,
      details: {
        table_name: statement.relation.relname,
        old_constraint_name: statement.subname,
        new_constraint_name: statement.newname
      }
    }
  end

  # Unknown mutations

  def self.unknown(statement)
    {
      mutation: :unknown,
      type: :unknown,
      details: {
        statement: statement.to_s
      }
    }
  end
end
