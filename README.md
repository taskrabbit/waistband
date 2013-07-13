# Waistband

Ruby interface to Elastic Search

## Installation

Install ElasticSearch:

```bash
brew install elasticsearch
```

Add this line to your application's Gemfile:

    gem 'waistband'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install waistband

## Configuration

Configuration is generally pretty simple.  First, create a folder where you'll store your Waistband configuration docs, usually under `#{APP_DIR}/config/waistband/`, you can also just throw it under `#{APP_DIR}/config/` if you want.  The baseline config contains something like this:

```yml
# #{APP_DIR}/config/waistband/waistband.yml
development:
  host: http://localhost
  port: 9200
```

You'll need a separate config file for each index you use, containing the index settings and mappings.  For example, for my search index, I use something akin to this:

```yml
# #{APP_DIR}/config/waistband/waistband_search.yml
development:
  name: search
  stringify: false
  settings:
    number_of_shards: 4
  mappings:
    event:
      _source:
        includes: ["*"]
```

## List of config settings:

* `name`: name of the index.  You can (and probably should) have a different name for the index for your test environment.
* `stringify`: determines wether whatever is stored into the index is going to be converted to a string before storage.  Usually false unless you need it to be true for specific cases, like if for some `key => value` pairs the value is of different types some times.
* `settings`: settings for the Elastic Search index.  Refer to the ["admin indices update settings"](http://www.elasticsearch.org/guide/reference/api/admin-indices-update-settings/) document for more info.
* `mappings`: the index mappings.  More often than not you'll want to include all of the document attribute, so you'll do something like in the example above.  For more info, refer to the [mapping reference]("http://www.elasticsearch.org/guide/reference/mapping/").

## Initializer

After getting all the YML config files in place, you'll just need to hook up an initializer to these files:

```ruby
# #{APP_DIR}/config/initializers/waistband.rb
Waistband.configure do |c|
  c.config_dir = "#{APP_DIR}/spec/config/waistband"
end
```

## Usage

### Indexes


#### Creating and destroying the indexes

For each index you have, you'll probably want to make sure it's created on initialization, so either in the same waistband initializer or in another initializer, depending on your preferences, you'll have to create them.  For our search example:

```ruby
# #{APP_DIR}/config/initializers/waistband.rb
# ...
Waistband::Index.new('search').create!
```

This will create the index if it's not been created already or return nil if it already exists.

Destroying an index is equally easy:

```ruby
Waistband::Index.new('search').destroy!
```

When writing tests, it would generally be advisable to destroy and create the indexes in a `before(:each)` or `before(:all)` depending in your circumstances.  Also, remember for testing that replication and data availability is not inmediate on the indexes, so if you create an immediate expectation for data to be there, you should refresh the index before it:

```ruby
Waistband::Index.new('search').refresh
```

#### Writing, reading and deleting from an index

```ruby
index = Waistband::Index.new('search')

# writing
index.store!('my_data', {'important' => true, 'valuable' => {'always' => true}})
# => "{\"ok\":true,\"_index\":\"search\",\"_type\":\"search\",\"_id\":\"my_data\",\"_version\":1}"

# reading
index.read('my_data')
# => {"important"=>true, "valuable"=>{"always"=>true}}

# deleting
index.delete!('my_data')
# => "{\"ok\":true,\"found\":true,\"_index\":\"search\",\"_type\":\"search\",\"_id\":\"my_data\",\"_version\":2}"

# reading non-existent data
index.read('my_data')
# => nil
```

### Searching

For searching, Waistband has the Query class available:

```ruby
index = Waistband::Index.new('search')
query = index.query('shopping')
query.add_fields('name', 'description') # look for the search term `shopping` in the attributes `name` and `description`
query.add_term('task', 'true')          # only in documents where the attribute task is set to true

query.results # => returns an array of Waistband::QueryResult

query.total_hits
# => 28481

# get the second page of results:
query.page = 2
query.results

# change the page size:
query.page_size = 50
query.page = 1
query.results
```

For paginating the results, you can use the `#paginated_results` method, which requires the [Kaminari](https://github.com/amatsuda/kaminari), gem.  If you use another gem, you can just override the method, etc.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
