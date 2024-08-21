Gem::Specification.new do |spec|
  spec.name          = 'kamalx'
  spec.version       = '1.0.0'
  spec.authors       = ['Lucas Carlson']
  spec.email         = ['lucas@carlson.net']

  spec.summary       = 'A command-line tool for parsing logs.'
  spec.description   = 'kamalx makes the kamal deploy tool more user-friendly and easier to watch and understand.'
  spec.homepage      = 'https://github.com/cardmagic/kamalx'
  spec.license       = 'MIT'

  spec.files         = Dir['bin/**/*', 'lib/**/*', 'Gemfile', 'LICENSE.md', 'README.md']
  spec.bindir        = 'bin'
  spec.executables   = ['kamalx']
  spec.require_paths = ['lib']

  spec.add_dependency 'curses'
  spec.add_dependency 'eventmachine'
  spec.add_dependency 'kamal'
end
