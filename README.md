# Waistband

Configuration and sensible defaults for ElasticSearch on Ruby.  Handles configuration, index creation, quality of life, etc, of Elastic Search in Ruby.

# Installation

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
    retries: 5
    timeout: 2
    reload_on_failure: true
    servers:
        server1:
            protocol: http
            host: localhost
            port: 9200
```

You can name the servers whatever you want, and one of them is selected at random using `Array.sample`, excluding blacklisted servers, when conduction operations on the server.  Here's an example with two servers:

```yml
# #{APP_DIR}/config/waistband/waistband.yml
development:
    retries: 5
    timeout: 2
    reload_on_failure: true
    servers:
        server1:
            protocol: http
            host: 173.247.192.214
            port: 9200
        server2:
            protocol: http
            host: 173.247.192.215
            port: 9200
```

You'll need a separate config file for each index you use, containing the index settings and mappings.  For example, for my search index, I use something akin to this:

```yml
# #{APP_DIR}/config/waistband/waistband_search.yml
development:
    stringify: false
    settings:
        index:
            number_of_shards: 4
    mappings:
        event:
            _source:
                includes: ["*"]
```

## List of config settings:

* `settings`: settings for the Elastic Search index.  Refer to the ["admin indices update settings"](http://www.elasticsearch.org/guide/reference/api/admin-indices-update-settings/) document for more info.
* `mappings`: the index mappings.  More often than not you'll want to include all of the document attribute, so you'll do something like in the example above.  For more info, refer to the [mapping reference]("http://www.elasticsearch.org/guide/reference/mapping/").
* `retries`: number of times to retry before moving on to the next server node.
* `reload_on_failure`: should we reload the node list from the server on failure.
* `timeout`: seconds till a timeout exception is raise when trying to connect to the node.
* `name`: optional - name of the index.  You can (and probably should) have a different name for the index for your test environment.  If not specified, it defaults to the name of the yml file minus the `waistband_` portion, so in the above example, the index name would become `search_#{env}`, where env is your environment variable as defined in `Waistband::Configuration#setup` (determined by `RAILS_ENV` or `RACK_ENV`).
* `stringify`: optional - determines wether whatever is stored into the index is going to be converted to a string before storage.  Usually false unless you need it to be true for specific cases, like if for some `key => value` pairs the value is of different types some times.

## Initializer


Waistband will look for config files by default in `File.join(Rails.root, 'config')`.  You can override the default location of the config folder. After getting all the YML config files in place, you'll just need to hook up an initializer to these files:

```ruby
# #{APP_DIR}/config/initializers/waistband.rb
Waistband.configure do |c|
    c.config_dir = "#{APP_DIR}/spec/config/waistband"
end
```

## Usage

### Indexes


#### Creating and destroying the indexes

For each index you have, you'll probably want to make sure it's created on initialization, or in a Rake task, so either in the same waistband initializer or in another initializer, depending on your preferences, you'll have to create them.  For our search example:

```ruby
# #{APP_DIR}/config/initializers/waistband.rb
# ...
Waistband::Index.new('search').create
```

This will create the index if it's not been created already or return nil if it already exists.  If you want to raise an exception if it already exists, use the `#create!` method.

Destroying an index is equally easy:

```ruby
Waistband::Index.new('search').delete
```

When writing tests, it would generally be advisable to destroy and create the indexes in a `before(:each)` or `before(:all)` depending in your circumstances.  Also, remember for testing that replication and data availability is not inmediate on the indexes, so if you create an immediate expectation for data to be there, you should refresh the index before it:

```ruby
Waistband::Index.new('search').refresh
```

Note: most index methods such as `create`, `delete`, etc, have an equivalent bang method (`delete!`) that will actually throw an exception if something goes wrong.  For example, `delete` will return nil if the index doesn't exist, but will raise any other unrelated exceptions, whereas `delete!` will raise even the Index Not Found exception.

#### Writing, reading and deleting from an index

```ruby
index = Waistband::Index.new('search')

# writing
index.save('my_data', {'important' => true, 'valuable' => {'always' => true}}) # => true

# reading
index.find('my_data') # => {"important"=>true, "valuable"=>{"always"=>true}}

# reading with all the internal data
index.read('my_data') # => {'_id' => '123123', '_source' => {"important"=>true, "valuable"=>{"always"=>true}}, ...}

# deleting
index.destroy('my_data') # => "{\"ok\":true,\"found\":true,\"_index\":\"search\",\"_type\":\"search\",\"_id\":\"my_data\",\"_version\":2}"

# reading non-existent data
index.find('my_data') # => nil
```

### Searching

For searching, you construct a search from your index:

```ruby
index = Waistband::Index.new('search')
results = index.search({
    query: {
        term: { hidden: false }
    },
    sort: { created_at: {order: 'desc' } },
    page: 1,
    page_size: 5
})

results.hits # => returns a search results object
results.total_hits # => 28481
```

For paginating the results, you can use the `#paginated_results` method, which requires the [Kaminari](https://github.com/amatsuda/kaminari), gem.  If you use another gem, you can just override the method, etc.

For more information and extra methods, take a peek into the class docs.

Also, for convenience, the gem provides the `Result` class, which just provides some quality-of-life methods for working with search result hashes or their inner `_source` hashes, for example:

```ruby
search = index.search({
    query: {
        term: { hidden: false }
    }
})
results = search.results
result = result.first

result._id # => '123123'
result._type # => 'search_result'
result._index # => 'search'
result.task_id # => 991122 -- note that this is a method missing interface directly either to the search result hash, or to the _source sub-hash
```

The `Result` class is directly exposed via two methods in the `SearchResults` class: `#results` and `#paginated_results`.  You can use `#paginated_results` if you're using Kaminari for pagination and wish to use the awesomeness it provides.

### Index Aliasing

Sometimes it can be useful to sub-divide your index into smaller indexes based on dates or other partitioning schemes.  To do this, the `Index` class exposes the `subs` option on instantiation:

```ruby
index = Waistband::Index.new('events', subs: %w(2013 01))
index.create!
```

This creates the index `events__2013_01`, which in your application logic you could design to store all event data for Jan 2013.  You'd do the same for Feb, etc., and when you no longer need one of the older ones, you could delete just that sub-index, instead of things getting more complicated.

### Aliasing

Part of subbing is gonna be creating the correct aliases that group up your sub-indexes.

```ruby
index = Waistband::Index.new('events', subs: %w(2013 01))
index.create!
index.alias('my_super_events_alias') # => true
index.alias_exists?('my_super_events_alias') # => true
```

The `alias` methods receives a param to define the alias name.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

