$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'mongoid/versioning/version'

Gem::Specification.new do |gem|
  gem.name          = 'mongoid-versioning'
  gem.version       = Mongoid::Versioning::VERSION
  gem.authors       = ['Jaci Brunning']
  gem.email         = ['jaci.brunning@mgail.com']
  gem.homepage      = 'https://github.com/JaciBrunning/mongoid-versioning'
  gem.summary       = 'Custom versioning, inspired by Mongoid::Versioning by Durran Jordan and Mario Uher'
  gem.description   = ''
  gem.licenses      = ['MIT']

  gem.files         = `git ls-files`.split("\n")
  gem.require_path  = 'lib'

  gem.add_dependency 'activesupport', '>= 4.0'
  gem.add_dependency 'mongoid', '>= 7.0.0'
  gem.add_development_dependency 'rake', '~> 10.0'
  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'timecop'
end
