# frozen_string_literal: true

require "test_helper"

class TestPgDelta < Minitest::Test
  # Column mutations

  def test_alter_table_add_column
    query = %(
      alter table foo
        add column bar varchar;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_add_column,
      type: :column,
      details: {
        table_name: "foo",
        column_name: "bar",
        column_type: "varchar"
      }
    }

    assert_equal expected, actual

    query = %(
      alter table foo
        add column bar boolean not null default false;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_add_column,
      type: :column,
      details: {
        table_name: "foo",
        column_name: "bar",
        column_type: "bool"
      }
    }

    assert_equal expected, actual

    query = %(
      alter table foo
        add column bar my_custom_type;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_add_column,
      type: :column,
      details: {
        table_name: "foo",
        column_name: "bar",
        column_type: "my_custom_type"
      }
    }

    assert_equal expected, actual
  end

  def test_alter_table_set_column_default
    query = %(
      alter table foo
        alter column bar set default true;
    )

    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_set_column_default,
      type: :column,
      details: {
        table_name: "foo",
        column_name: "bar"
      }
    }

    assert_equal expected, actual
  end

  def test_drop_column_default
    query = %(
      alter table foo
        alter column bar drop default;
    )

    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_drop_column_default,
      type: :column,
      details: {
        table_name: "foo",
        column_name: "bar"
      }
    }

    assert_equal expected, actual
  end

  def test_alter_table_drop_column
    query = %(alter table foo drop column bar;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_drop_column,
      type: :column,
      details: {
        table_name: "foo",
        column_name: "bar"
      }
    }

    assert_equal expected, actual
  end

  def test_alter_table_drop_not_null
    query = %(
      alter table weather
        alter column degrees
        drop not null;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_drop_not_null,
      type: :column,
      details: {
        table_name: "weather",
        column_name: "degrees"
      }
    }

    assert_equal expected, actual
  end

  def test_alter_table_set_not_null
    query = %(
      alter table weather
        alter column degrees
        set not null;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_set_not_null,
      type: :column,
      details: {
        table_name: "weather",
        column_name: "degrees"
      }
    }

    assert_equal expected, actual
  end

  def test_rename_column
    query = %(alter table foo rename column bar to quux;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_rename_column,
      type: :column,
      details: {
        table_name: "foo",
        old_column_name: "bar",
        new_column_name: "quux"
      }
    }

    assert_equal expected, actual
  end

  # Domain mutations

  def test_alter_domain
    query = %(alter domain foo drop constraint foo_check;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_domain,
      type: :domain,
      details: {
        domain_name: "foo"
      }
    }

    assert_equal expected, actual
  end

  def test_create_domain
    query = %(create domain foo as numeric(10, 5);)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :create_domain,
      type: :domain,
      details: {
        domain_name: "foo"
      }
    }

    assert_equal expected, actual
  end

  def test_drop_domain
    query = %(drop domain foo;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :drop_domain,
      type: :domain,
      details: {
        domain_name: "foo"
      }
    }

    assert_equal expected, actual
  end

  # Enum mutations

  def test_alter_enum
    query = %(
      alter type foo
        add value 'bar' after 'baz';
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_enum,
      type: :enum,
      details: {
        enum_name: "foo"
      }
    }

    assert_equal expected, actual
  end

  def test_create_enum
    query = %(create type foo as enum ('a', 'b', 'c'))
    actual = PgDelta.parse_query query
    expected = {
      mutation: :create_enum,
      type: :enum,
      details: {
        enum_name: "foo"
      }
    }

    assert_equal expected, actual
  end

  # Function mutations

  def test_create_function
    query = %(
      create function do_something()
      returns trigger
      language 'plpgsql'
      as $$
      declare
        x;
      begin
        select foo
        into strict x
        from bar
        where id = NEW.z_id.;

        return null;
      end;
      $$;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :create_function,
      type: :function,
      details: {
        function_name: "do_something"
      }
    }

    assert_equal expected, actual
  end

  def test_drop_function
    query = %(drop function foo_bar_args();)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :drop_function,
      type: :function,
      details: {
        function_name: "foo_bar_args"
      }
    }

    assert_equal expected, actual

    query = %(drop function foo_bar;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :drop_function,
      type: :function,
      details: {
        function_name: "foo_bar"
      }
    }

    assert_equal expected, actual
  end

  def test_rename_function
    query = %(alter function foo() rename to bar;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :rename_function,
      type: :function,
      details: {
        old_function_name: "foo",
        new_function_name: "bar"
      }
    }

    assert_equal expected, actual
  end

  # Table mutations

  def test_create_table
    query = %(
      create table quux_codes (
        code int8 primary key check (code between 1 and 10),
        foo_id uuid references foo(id),
        created_at timestamptz not null,
        updated_at timestamptz not null
      );
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :create_table,
      type: :table,
      details: {
        table_name: "quux_codes"
      }
    }

    assert_equal expected, actual
  end

  def test_create_table_as
    query = %(
      create temp table foo AS (
        select s.bar_id
        from random r
        join super s ON (s.id = r.s_id)
      );
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :create_table_as,
      type: :table,
      details: {
        table_name: "foo"
      }
    }

    assert_equal expected, actual
  end

  def test_drop_table
    query = %(drop table if exists foo;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :drop_table,
      type: :table,
      details: {
        table_name: "foo"
      }
    }

    assert_equal expected, actual

    query = %(drop table foo;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :drop_table,
      type: :table,
      details: {
        table_name: "foo"
      }
    }

    assert_equal expected, actual
  end

  def test_rename_table
    query = %(
      alter table foo rename to bar;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :rename_table,
      type: :table,
      details: {
        old_table_name: "foo",
        new_table_name: "bar"
      }
    }

    assert_equal expected, actual
  end

  def test_truncate
    query = %(truncate table foo;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :truncate_table,
      type: :table,
      details: {
        table_names: ["foo"]
      }
    }

    assert_equal expected, actual

    query = %(truncate table foo, bar restart identity;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :truncate_table,
      type: :table,
      details: {
        table_names: ["foo", "bar"]
      }
    }

    assert_equal expected, actual
  end

  # Trigger mutations

  def test_create_trigger
    query = %(
      create trigger quux_codes_trigger
        before insert on quux_codes
        for each row execute procedure do_something();
    )

    actual = PgDelta.parse_query query
    expected = {
      mutation: :create_trigger,
      type: :trigger,
      details: {
        trigger_name: "quux_codes_trigger",
        table_name: "quux_codes"
      }
    }

    assert_equal expected, actual
  end

  def test_drop_trigger
    query = %(drop trigger foo_trigger on foo_table;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :drop_trigger,
      type: :trigger,
      details: {
        trigger_name: "foo_trigger",
        table_name: "foo_table"
      }
    }

    assert_equal expected, actual
  end

  def test_disable_trigger
    query = %(alter table foo disable trigger bar;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :disable_trigger,
      type: :trigger,
      details: {
        table_name: "foo",
        trigger_name: "bar"
      }
    }

    assert_equal expected, actual
  end

  def test_enable_trigger
    query = %(alter table foo enable trigger bar;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :enable_trigger,
      type: :trigger,
      details: {
        table_name: "foo",
        trigger_name: "bar"
      }
    }

    assert_equal expected, actual
  end

  def test_rename_trigger
    query = %(alter trigger foo on bar_table rename to quux;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :rename_trigger,
      type: :trigger,
      details: {
        table_name: "bar_table",
        old_trigger_name: "foo",
        new_trigger_name: "quux"
      }
    }

    assert_equal expected, actual
  end

  # Data mutations

  def test_delete
    query = %(
      delete from quux_codes;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :delete_data,
      type: :data,
      details: {
        table_name: "quux_codes"
      }
    }

    assert_equal expected, actual

    query = %(
      delete from quux_codes where foo_id is null;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :delete_data,
      type: :data,
      details: {
        table_name: "quux_codes"
      }
    }

    assert_equal expected, actual
  end

  def test_insert
    query = %(
      insert into quux_codes (code)
        select * from generate_series(1,9) code;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :insert_data,
      type: :data,
      details: {
        table_name: "quux_codes"
      }
    }

    assert_equal expected, actual
  end

  def test_update
    query = %(
      update foo
        set bar = null
        where bar is not null;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :update_data,
      type: :data,
      details: {
        table_name: "foo",
        column_names: ["bar"]
      }
    }

    assert_equal expected, actual

    query = %(
      update foo
        set
          bar = null,
          quux = "baz"

        where bar is not null;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :update_data,
      type: :data,
      details: {
        table_name: "foo",
        column_names: ["bar", "quux"]
      }
    }

    assert_equal expected, actual
  end

  # Index mutations

  def test_create_index
    query = %(create index on foo (bar);)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :create_index,
      type: :index,
      details: {
        table_name: "foo",
        column_names: ["bar"]
      }
    }

    assert_equal expected, actual

    query = %(create index on foo (bar, baz, quux);)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :create_index,
      type: :index,
      details: {
        table_name: "foo",
        column_names: ["bar", "baz", "quux"]
      }
    }

    assert_equal expected, actual
  end

  def test_drop_index
    query = %(drop index if exists foo_bar_idx;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :drop_index,
      type: :index,
      details: {
        index_name: "foo_bar_idx"
      }
    }

    assert_equal expected, actual

    query = %(drop index bar_baz_idx;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :drop_index,
      type: :index,
      details: {
        index_name: "bar_baz_idx"
      }
    }

    assert_equal expected, actual
  end

  def test_rename_index
    query = %(alter index foo rename to bar;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :rename_index,
      type: :index,
      details: {
        old_index_name: "foo",
        new_index_name: "bar"
      }
    }

    assert_equal expected, actual
  end

  # Type mutations

  def test_alter_table_alter_column_type
    query = %(
      alter table foo
        alter column bar type varchar
        using bar::custom_type;
    )

    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_alter_column_type,
      type: :column,
      details: {
        table_name: "foo",
        column_name: "bar",
        new_type_name: "varchar"
      }
    }

    assert_equal expected, actual
  end

  def test_drop_type
    query = %(drop type if exists foo;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :drop_type,
      type: :type,
      details: {
        type_name: "foo"
      }
    }

    assert_equal expected, actual
  end

  def test_rename_type
    query = %(alter type foo rename to bar;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :rename_type,
      type: :type,
      details: {
        old_type_name: "foo",
        new_type_name: "bar"
      }
    }

    assert_equal expected, actual
  end

  # View mutations

  def test_create_view
    query = %(create view foo as select 1;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :create_view,
      type: :view,
      details: {
        view_name: "foo"
      }
    }

    assert_equal expected, actual
  end

  def test_drop_materialized_view
    query = %(drop materialized view if exists foo;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :drop_materialized_view,
      type: :view,
      details: {
        view_name: "foo"
      }
    }

    assert_equal expected, actual
  end

  def test_drop_view
    query = %(drop view foo;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :drop_view,
      type: :view,
      details: {
        view_name: "foo"
      }
    }

    assert_equal expected, actual
  end

  # Constraint mutations

  def test_add_constraint
    query = %(
      alter table foo
        add constraint bar_matches
        foreign key("baz_id")
        references "baz" ("id")
        on delete restrict on update restrict;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_add_constraint,
      type: :constraint,
      details: {
        table_name: "foo",
        constraint_name: "bar_matches"
      }
    }

    assert_equal expected, actual
  end

  def test_drop_constraint
    query = %(alter table foo drop constraint if exists bar;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_drop_constraint,
      type: :constraint,
      details: {
        table_name: "foo",
        constraint_name: "bar"
      }
    }

    assert_equal expected, actual
  end

  def test_validate_constraint
    query = %(alter table foo validate constraint bar;)
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_validate_constraint,
      type: :constraint,
      details: {
        table_name: "foo",
        constraint_name: "bar"
      }
    }

    assert_equal expected, actual
  end

  def test_rename_constraint
    query = %(
      alter table foo
      rename constraint bar
      to baz;
    )
    actual = PgDelta.parse_query query
    expected = {
      mutation: :alter_table_rename_constraint,
      type: :constraint,
      details: {
        table_name: "foo",
        old_constraint_name: "bar",
        new_constraint_name: "baz"
      }
    }

    assert_equal expected, actual
  end
end
