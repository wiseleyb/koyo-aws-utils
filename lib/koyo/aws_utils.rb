# frozen_string_literal: true

require_relative "aws_utils/version"
require_relative "aws_utils/s3"

module Koyo
  module AwsUtils
    class Error < StandardError; end

    # some comment to appease rubocop
    class Test
      def self.test
        puts "jim"
      end
    end
  end
end
