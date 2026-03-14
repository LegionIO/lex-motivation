# frozen_string_literal: true

require_relative 'lib/legion/extensions/motivation/version'

Gem::Specification.new do |spec|
  spec.name          = 'legion-extensions-motivation'
  spec.version       = Legion::Extensions::Motivation::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@legionIO.com']
  spec.summary       = 'Goal-directed motivation and drive states for LegionIO cognitive agents'
  spec.description   = 'Models motivational drive states — why the agent acts, what energizes behavior, and how approach vs avoidance tendencies operate'
  spec.homepage      = 'https://github.com/LegionIO/lex-motivation'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.files = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.metadata['rubygems_mfa_required'] = 'true'
end
