Gem::Specification.new do |spec|
  spec.name          = 'kamalx'
  spec.version       = '1.0.1'
  spec.authors       = ['Lucas Carlson']
  spec.email         = ['lucas@carlson.net']

  spec.summary       = 'A wrapper for the kamal Docker deployment tool from Basecamp/37signals to make it easier to watch and understand the deployment process.'
  spec.description   = 'kamalx makes the kamal deploy tool more user-friendly and easier to watch and understand.'
  spec.homepage      = 'https://github.com/cardmagic/kamalx'
  spec.license       = 'MIT'

  spec.files         = Dir['bin/**/*', 'lib/**/*', 'spec/**/*', 'Gemfile', 'LICENSE.md', 'README.md']
  spec.bindir        = 'bin'
  spec.executables   = ['kamalx']
  spec.require_paths = ['lib']

  spec.add_dependency 'curses'
  spec.add_dependency 'eventmachine'
  spec.add_dependency 'kamal'
end
