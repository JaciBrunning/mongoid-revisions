$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'mongoid/revisions/version'

Gem::Specification.new do |gem|
  gem.name          = 'mongoid-revisions'
  gem.version       = Mongoid::Revisions::VERSION
  gem.authors       = ['Jaci Brunning']
  gem.email         = ['jaci.brunning@mgail.com']
  gem.homepage      = 'https://github.com/JaciBrunning/mongoid-revisions'
  gem.summary       = 'Keep revisions of your Mongoid documents to go back in time, inspired by Mongoid::Versioning by Durran Jordan and Mario Uher'
  gem.licenses      = ['MIT']

  gem.files         = `git ls-files`.split("\n")
  gem.require_path  = 'lib'

  gem.add_dependency 'activesupport', '>= 4.0'
  gem.add_dependency 'mongoid', '>= 7.0.0'
  gem.add_development_dependency 'rake', '~> 10.0'
  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'timecop'
end
