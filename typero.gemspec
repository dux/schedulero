version = File.read File.expand_path '.version', File.dirname(__FILE__)

Gem::Specification.new 'schedulero', version do |s|
  s.summary     = 'Simple scheduler'
  s.description = 'Super simple scheduler that will run tasks every x seconds/minutes/hours'
  s.authors     = ["Dino Reic"]
  s.email       = 'reic.dino@gmail.com'
  s.files       = Dir['./lib/**/*.rb']+['./.version']
  s.homepage    = 'https://github.com/dux/typero'
  s.license     = 'MIT'

  s.add_runtime_dependency 'as-duration', '~> 0'
  s.add_runtime_dependency 'colorize', '~> 0'
end