# SidekiqSpread

Add 'perform_spread' method to workers to allow for scheduling jobs over an interval of time

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq_spread'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq_spread

## Usage

You can find the docs on [rubdoc.info](https://www.rubydoc.info/github/Latermedia/sidekiq_spread/master).

### Basic usage

This will randomly scheduled a job sometime with in the next hour.

```ruby
class MyWorker
  include Sidekiq::Worker
  include SidekiqSpread

  def perform(arg)
    # ...
  end
end

MyWorker.perform_spread('arg1')
```

### Parameters

* `spread_duration` - Size of window, in seconds, to spread jobs out over, defaults to 1 hour, will convert to seconds via `to_i`
* `spread_in` - Start of window offset from now, in seconds, defaults to 0, will convert to seconds via `to_i`
* `spread_at` - Start of window offset timestamp, defaults to now
* `spread_method` - Perform either a random or modulo spread, defaults to `rand`
* `spread_mod_value` - Value to use for determining mod offset, defaults to cast first argument to an Integer via `to_i`


`spread_duation` and `spread_method` can be set via `sidekiq_opions` in the worker class. If the same option is passed via the `perform_spread` method, it will override the `sidekiq_options` value for that job.

```ruby
class MyWorker
  include Sidekiq::Worker
  include SidekiqSpread

  sidekiq_options queue: :task, spread_duration: 2.hours, spread_method: :mod

  def perform(arg)
    # ...
  end
end
```

### Other Exmaples

```ruby
# Will schedule this job sometime within the next day
MyWorker.perform_spread('arg1', spread_duration: 1.day)

# Will schedule this job 1056 seconds from now:
# first argument cast to an integer modulo the `spread_duration` (1 hour) in seconds (3600)
# 123456 % 3600 = 1056
MyWorker.perform_spread('123456', spread_method: :mod)

# Will schedule this job 30 seconds from now
# 3630 % 3600 = 30
MyWorker.perform_spread(123456, spread_method: :mod, spread_mod_value: 3630)

# Will schedule this job 1116 seconds from now:
# first argument cast to an integer modulo the `spread_duration` (1 hour) in seconds (3600),
# plus 1 minute in seconds (60)
# 123456 % 3600 + 60 = 1116
MyWorker.perform_spread('123456', spread_method: :mod, spread_in: 1.minute)
```

### Name Arguments

Sidkiq doesn't place nicely with [named arguments](https://github.com/mperham/sidekiq/wiki/Best-Practices) and they will mess up some some of the argument parsing going on in this gem. Therefore this gem raises and `ArgumentError` if you try to use named arguments.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Tests

To run the tests:

```bash
rspec spec
```

Tests are currently run against the following Ruby version:
- 2.5
- 2.4
- 2.3
- 2.2

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Latermedia/sidekiq_spread. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SidekiqSpread project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Latermedia/sidekiq_spread/blob/master/CODE_OF_CONDUCT.md).
