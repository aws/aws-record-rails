# Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not
# use this file except in compliance with the License. A copy of the License is
# located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions
# and limitations under the License.

module AwsRecord
  module Generators
    class GeneratedAttribute

      OPTS = %w(hkey rkey persist_nil db_attr_name ddb_type default_value)
      INVALID_HKEY_TYPES = %i(map_attr list_attr numeric_set_attr string_set_attr)
      attr_reader :name, :type
      attr_accessor :options

      class << self

        def parse(field_definition)
          name, type, opts = field_definition.split(':')
          type = "string" if not type
          type, opts = "string", type if OPTS.any? { |opt| type.include? opt }
          
          opts = opts.split(',') if opts
          type, opts = parse_type_and_options(name, type, opts)
          validate_opt_combs(name, type, opts)

          new(name, type, opts)
        end

        private

        def validate_opt_combs(name, type, opts)
          if opts
              is_hkey = opts.key?(:hash_key)
              is_rkey = opts.key?(:range_key)

              raise ArgumentError.new("Field #{name} cannot be a range key and hash key simultaneously") if is_hkey && is_rkey
              raise ArgumentError.new("Field #{name} cannot be a hash key and be of type #{type}") if is_hkey and INVALID_HKEY_TYPES.include? type 
          end
        end
        
        def parse_type_and_options(name, type, opts)
          opts = [] if not opts
          return parse_type(name, type), opts.map { |opt| parse_option(name, opt) }.to_h
        end

        def parse_option(name, opt)
          case opt

          when "hkey"
            return :hash_key, true 
          when "rkey"
            return :range_key, true
          when "persist_nil"
            return :persist_nil, true
          when /db_attr_name\{(\w+)\}/
            return :database_attribute_name, '"' + $1 + '"'
          when /ddb_type\{(S|N|B|BOOL|SS|NS|BS|M|L)\}/i
            return :dynamodb_type, '"' + $1.upcase + '"'
          when /default_value\{(.+)\}/
            return :default_value, $1
          else
            raise ArgumentError.new("You provided an invalid option for #{name}: #{opt}")
          end
        end

        def parse_type(name, type)
          case type.downcase

          when "bool", "boolean"
            :boolean_attr
          when "date"
            :date_attr
          when "datetime"
            :datetime_attr
          when "float"
            :float_attr
          when "int", "integer"
            :integer_attr
          when "list"
            :list_attr
          when "map"
            :map_attr
          when "num_set", "numeric_set", "nset"
            :numeric_set_attr
          when "string_set", "s_set", "sset"
            :string_set_attr
          when "string"
            :string_attr
          else
            raise ArgumentError.new("Invalid type for #{name}: #{type}")
          end
        end
      end

      def initialize(name, type = :string_attr, options = {})
        @name = name
        @type = type
        @options = options
      end
    end
  end
end
