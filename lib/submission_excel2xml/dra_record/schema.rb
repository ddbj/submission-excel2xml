require 'json'

# What the v3 schema (DDBJRecord::V3::SCHEMA) says is at a place of the SRA
# mapping: the JSON type of its value, so the converter can write `"true"` as
# true and `"36"` as 36 where the spec types them.
module SubmissionExcel2xml::DRARecord::Schema
  module_function

  # The JSON type at `place` (a Mapping::Place): of the value there, or,
  # for a place ending in a list, of the list's elements.
  def type_at(place)
    (@types ||= {})[place] ||= begin
      node = place.segments.reduce(root) {|schema, segment|
        field = resolve(schema).fetch('properties').fetch(segment.name) { raise KeyError, "#{place}: the schema has no #{segment.name}" }
        field = resolve(field)
        field = resolve(field.fetch('items'))                if segment.list
        field = resolve(field.fetch('additionalProperties')) if segment.key
        field
      }

      node['type'] || ('object' if node.key?('properties'))
    end
  end

  def root = @root ||= JSON.parse(File.read(File.expand_path('data/v3.schema.json', __dir__)))

  # A $ref followed, and `anyOf: [X, null]` taken as X.
  def resolve(schema)
    schema = root.dig('$defs', schema['$ref'].delete_prefix('#/$defs/')) if schema['$ref']
    schema = resolve(schema['anyOf'].find { _1['type'] != 'null' }) if schema['anyOf']
    schema
  end
end
