# PgDelta

`pg_delta` provides an easy way to obtain information about a PostgreSQL query.
Here's a motivating example.

Given a file `/tmp/a.sql`:


```sql
update users
  set name = 'Unknown'
  where name is null;

alter table users
  alter column name
  set not null;

truncate table passwords;
```

Running `pg_delta` will then yield the following JSON:

```sh
$ exe/pg_delta -f /tmp/a.sql
[
  {
    "mutation": "update_data",
    "type": "data",
    "details": {
      "table_name": "users",
      "column_names": [
        "name"
      ]
    }
  },
  {
    "mutation": "alter_table_set_not_null",
    "type": "column",
    "details": {
      "table_name": "users",
      "column_name": "name"
    }
  },
  {
    "mutation": "truncate_table",
    "type": "table",
    "details": {
      "table_names": [
        "passwords"
      ]
    }
  }
]
```

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add pg_delta

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install pg_delta

## Usage

```
Usage: pg_delta -f FILES

Example:
  $ pg_delta -f 1.sql 2.sql 3.sql

Options:
    -v, --version                    Print the version
    -f, --files FILES                The files to parse
    -h, --help                       Show this message
```

### Types of Changes

The `type`s of changes are as follows:

```
:column
:domain
:enum
:function
:table
:trigger
:data
:index
:type
:view
:constraint
:unknown
```

### Mutations

The following `mutation`s are identified:

```
# :column
:alter_table_add_column
:alter_table_set_column_default
:alter_table_drop_column_default
:alter_table_drop_column
:alter_table_drop_not_null
:alter_table_set_not_null
:alter_table_rename_column

# :domain
:alter_domain
:create_domain
:drop_domain

# :enum
:alter_enum
:create_enum

# :function
:create_function
:drop_function
:rename_function

# :table
:create_table
:create_table_as
:drop_table
:rename_table
:truncate_table

# :trigger
:create_trigger
:drop_trigger
:disable_trigger
:enable_trigger
:rename_trigger

# :data
:delete_data
:insert_data
:update_data

# :index
:create_index
:drop_index
:rename_index

# :type
:alter_table_alter_column_type
:drop_type
:rename_type

# :view
:create_view
:drop_materialized_view
:drop_view

# :constraint
:alter_table_add_constraint
:alter_table_drop_constraint
:alter_table_validate_constraint
:alter_table_rename_constraint

# :unknown
:unknown
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/rhizomic/pg_delta. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](https://github.com/rhizomic/pg_delta/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
