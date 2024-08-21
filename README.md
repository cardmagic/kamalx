# KamalX

KamalX is a command-line tool that enhances the user experience of the [kamal](https://github.com/basecamp/kamal) deploy tool from Basecamp by making it more user-friendly and easier to watch and understand.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kamalx'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install kamalx
```

## Usage

After installation, you can use KamalX by running:

```
$ kamalx [kamal_commands]
```

Replace `[kamal_commands]` with any commands you would normally pass to kamal.

## Features

- Interactive progress bar
- Colored output for better readability
- Separated stage history and command output windows

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cardmagic/kamalx/issues

## License

The gem is available as open source under the terms of the MIT License. See `LICENSE.md` for more details.