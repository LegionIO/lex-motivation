# frozen_string_literal: true

require 'legion/extensions/motivation/version'
require 'legion/extensions/motivation/helpers/constants'
require 'legion/extensions/motivation/helpers/drive_state'
require 'legion/extensions/motivation/helpers/motivation_store'
require 'legion/extensions/motivation/runners/motivation'
require 'legion/extensions/motivation/client'

module Legion
  module Extensions
    module Motivation
      extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core)
    end
  end
end
