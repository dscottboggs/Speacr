# Speacr
#### Bindings to libespeak (eSpeak) for Crystal

The bindings are complete and documented, but use fails currently for me when it
fails to find an audio device.


## Installation
1. Add the dependency to your `shard.yml`:
```yaml
dependencies:
  espeak.cr:
    github: your-github-user/espeak.cr
```
2. Run `shards install`

## Usage

```crystal
require "Speacr"
Speacr::Speaker.new.say "something"
```


## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/espeak.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [D. Scott Boggs](https://github.com/your-github-user) - creator and maintainer
