# frozen_string_literal: true

require 'legion/extensions/motivation/helpers/constants'
require 'legion/extensions/motivation/helpers/drive_state'
require 'legion/extensions/motivation/helpers/motivation_store'
require 'legion/extensions/motivation/runners/motivation'

module Legion
  module Extensions
    module Motivation
      class Client
        include Runners::Motivation

        attr_reader :motivation_store

        def initialize(motivation_store: nil, **)
          @motivation_store = motivation_store || Helpers::MotivationStore.new
        end
      end
    end
  end
end
