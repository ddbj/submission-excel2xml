require 'nokogiri'

module SubmissionExcel2xml
  module DRARecord; end
end

require_relative 'mapping'
require_relative 'schema'

# Ported from ddbj-repository's DRA::Converter.
#
# SRA XML (the documents of one DRA submission: SUBMISSION, STUDY, SAMPLE,
# EXPERIMENT, RUN, ANALYSIS, each alone or in its *_SET) to a DDBJ Record v3
# record, by the spec's table (Mapping).
#
# Nothing is converted by hand but what the table's notes say. Every element
# and attribute is looked up in the table, and one the table does not have
# raises Unmapped, as does text where the table takes none: the table is the
# spec's account of everything SRA XML can hold, so an item outside it is one
# the record would lose.
#
# A place inside a list names the element being built for the XML element
# the list's elements stand for (Mapping.anchor): its attributes, its
# text and its descendants write into the same element (`STUDY/@accession`
# and `STUDY/DESCRIPTOR/STUDY_TITLE` into one of `projects[]`), and a sibling
# XML element starts another. A row naming a list element itself
# (`SUBMISSION/ACTIONS/ACTION: submission.sra.actions[]`) starts one even if
# nothing is written into it.
class SubmissionExcel2xml::DRARecord::Converter
  Mapping = SubmissionExcel2xml::DRARecord::Mapping
  Schema  = SubmissionExcel2xml::DRARecord::Schema

  SOURCE_FORMAT = 'excel2xml_dra'.freeze
  SAFE_MAX      = (2**53) - 1

  class Unmapped < StandardError; end

  # The list a document's root element is an element of, and the kind a
  # relation names it by (`source.type`).
  ROOT_LISTS = {
    'study'      => ['projects[]',    'project'],
    'sample'     => ['samples[]',     'sample'],
    'experiment' => ['experiments[]', 'experiment'],
    'run'        => ['runs[]',        'run'],
    'analysis'   => ['analyses[]',    'analysis']
  }.freeze

  BOOLEANS = {'true' => true, 'false' => false, '1' => true, '0' => false}.freeze
  INTEGER  = /\A[+-]?\d+\z/
  NUMBER   = /\A[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\z/

  def initialize(documents:)
    @documents = documents
  end

  def call
    @record    = {'schema_version' => 'v3', 'provenance' => {'source_format' => SOURCE_FORMAT}}
    @relations = []
    @restarts  = {}.compare_by_identity
    @roots     = {}.compare_by_identity
    @alsos     = {}

    @documents.each do |xml|
      documents_in(Nokogiri::XML(xml, &:strict).root).each do |element|
        kind = Mapping::ROOTS.fetch(name_of(element)) { raise Unmapped, "#{name_of(element)}: not an SRA document" }

        walk(element, kind:, path: name_of(element), frames: [], frame: root_frame(kind, name_of(element)))
      end
    end

    @alsos.each { copy_from_action_in_force(*_1) }

    prune(@record)

    # An object with nothing of its own is no object a record can name
    # (relations and all are elsewhere), and an ordered list cannot hold it.
    @roots.each do |object, name|
      raise Unmapped, "#{name}: a document carrying nothing of its own" if object.empty?
    end

    @relations.each { resolve_source(*_1) }

    @record
  end

  private

  # A *_SET holds documents of its kind and nothing else.
  def documents_in(root)
    name = name_of(root)

    return [root] unless name.end_with?('_SET')

    raise Unmapped, "#{name}: attributes on a set" if root.attribute_nodes.any?
    raise Unmapped, "#{name}: text in a set"       if own_text(root, name)

    root.element_children.each do |element|
      raise Unmapped, "#{name}/#{name_of(element)}: not a #{name.delete_suffix('_SET')}" unless name_of(element) == name.delete_suffix('_SET')
    end
  end

  # The name an element or attribute is looked up by: with its prefix, so
  # one in another namespace is not taken for SRA's own.
  def name_of(node) = [node.namespace&.prefix, node.name].compact.join(':')

  # The frame of a document's root element, holding the object the document
  # is. It is there before anything is written into it, since a STUDY's rows
  # do not name the list element its project is.
  def root_frame(kind, name)
    list, = ROOT_LISTS[kind]

    return {} unless list

    object = {}

    (@record[list.delete_suffix('[]')] ||= []) << object
    @roots[object] = name

    {list => object}
  end

  # One XML element: its row, its attributes, its text, its children, in a
  # frame of its own so what it starts is its descendants' alone.
  def walk(element, kind:, path:, frames:, frame: {})
    frames = [*frames, frame]
    place  = place!(kind, path)
    text   = own_text(element, path)

    if place == :container || Schema.type_at(place) == 'object'
      raise Unmapped, "#{path}: text where the table takes none" if text

      walk_segments(place.segments, place, frames, kind:, path:) if place != :container && place.element?
    elsif (value = place.value_of(element.name))
      raise Unmapped, "#{path}: text where the element's name is the value" if text

      write(place, value, frames, kind:, path:)
    elsif text
      write(place, text, frames, kind:, path:)
    end

    element.attribute_nodes.each do |attribute|
      next if attribute.value.empty?

      attribute_path = "#{path}/@#{name_of(attribute)}"

      write(place!(kind, attribute_path), attribute.value, frames, kind:, path: attribute_path)
    end

    element.element_children.each do |child|
      walk(child, kind:, path: "#{path}/#{name_of(child)}", frames:)
    end
  end

  def place!(kind, path)
    Mapping.place(kind, path) || raise(Unmapped, "#{path}: not in the SRA mapping")
  end

  # An element's own text, CDATA included. An entity reference the parser
  # leaves unexpanded (one the document's DTD declares) would drop out of it.
  def own_text(element, path)
    raise Unmapped, "#{path}: an entity reference" if element.children.any? { _1.is_a?(Nokogiri::XML::EntityReference) }

    element.children.select { _1.text? || _1.cdata? }.map(&:content).join.then { _1 unless _1.match?(/\A[[:space:]]*\z/) }
  end

  def write(place, value, frames, kind:, path:)
    *outer, last = place.segments
    value        = place.note == Mapping::KIND_NAME ? kind_name(value, path) : cast(place, value, path)
    target       = walk_segments(outer, place, frames, kind:, path:)

    # A list element the table does not name, built from its XML element's
    # children (`SAMPLE_ATTRIBUTES/TAG`, `SAMPLE_ATTRIBUTES/VALUE`, … with no
    # SAMPLE_ATTRIBUTE around each pair), ends where one of its places comes
    # round again.
    if !last.list && filled?(target, last) && (restart = @restarts[target])
      restart.call
      target = walk_segments(outer, place, frames, kind:, path:)
    end

    if last.list
      (target[last.name] ||= []) << value
    elsif last.key
      put(target[last.name] ||= {}, last.key, value, path)
    else
      put(target, last.name, value, path)
    end

    @alsos[place] ||= place.also if place.also
  end

  # `@target の無い HOLD と RELEASE のうち最後のものなら、submission.hold_date
  # にも同じ値`: ACTIONS are carried out in the order written, so of the
  # HOLDs and RELEASEs naming no target the last is the one in force. Only
  # known once every action is read. A RELEASE, or a HOLD with no date (a
  # period only), leaves no hold date.
  def copy_from_action_in_force(place, also)
    *actions, value = place.segments
    list            = actions.reduce(@record) {|object, segment| object&.dig(segment.name) }
    in_force        = Array(list).select { %w[HOLD RELEASE].include?(_1['type']) && !_1.key?('target') }.last

    return unless (date = in_force&.dig(value.name))

    *outer, last = also.segments

    put(outer.reduce(@record) {|object, segment| object[segment.name] ||= {} }, last.name, date, place.to_s)
  end

  def filled?(target, last) = !(last.key ? target[last.name]&.dig(last.key) : target[last.name]).nil?

  # Two items the table puts in one place would leave only the second.
  def put(object, key, value, path)
    raise Unmapped, "#{path}: #{key} is written twice (#{object[key].inspect}, #{value.inspect})" if object.key?(key)

    object[key] = value
  end

  def walk_segments(segments, place, frames, kind:, path:)
    segments.each_with_index.reduce(@record) {|object, (segment, index)|
      if segment.list
        prefix       = place.segments[0..index].map(&:bare).join('.')
        depth, named = Mapping.anchor(kind, path, place, index)
        frame        = frames[depth - 1]

        (frame[prefix] || start_element(object, segment, prefix, frame, restartable: !named && depth < frames.size, root_frame: frames.first, kind:)).tap {
          annotate(_1, segment, path)
        }
      elsif segment.key
        (object[segment.name] ||= {})[segment.key] ||= {}
      else
        object[segment.name] ||= {}
      end
    }
  end

  # A new element of a list, held by the frame of the XML element it stands
  # for, so that element's other items find it. One the table does not name,
  # built from the children of the element holding it, can be ended early
  # (see #write).
  def start_element(object, segment, prefix, frame, restartable:, root_frame:, kind:)
    element = {}

    (object[segment.name] ||= []) << element
    frame[prefix] = element

    @restarts[element] = -> { frame.delete(prefix) } if restartable

    # A relation's source is the document's root object, named once the whole
    # record is known (by alias, it may need an index among its namesakes).
    @relations << [element, kind, root_frame] if prefix == 'relations[]'

    element
  end

  # `identifiers[external]`, `relations[part_of sample]`: the words are the
  # element's type and, for a relation, its target's db — the same for every
  # item that writes into the element.
  def annotate(element, segment, path)
    type, db = segment.annotation

    put(element, 'type', type, path) if type && element['type'] != type
    put(element['target'] ||= {}, 'db', db, path) if db && element.dig('target', 'db') != db
  end

  def resolve_source(relation, kind, root_frame)
    relation['source'] =
      if kind == 'submission'
        {'type' => 'submission', **@record.fetch('submission', {}).slice('accession', 'alias')}
      else
        list, type = ROOT_LISTS.fetch(kind)

        {'type' => type, **reference(root_frame.fetch(list), list.delete_suffix('[]'))}
      end
  end

  # An object by accession, else by alias — with its position among the
  # objects sharing that alias when it does not name one alone
  # (ddbj/ddbj-record-specifications#18).
  def reference(object, list)
    return {'accession' => object['accession']} if object['accession']

    {'alias' => object['alias'], 'index' => namesake_indexes(list).fetch(object)}.compact
  end

  # Each object of a list's position among those sharing its alias, or nil
  # for one that shares it with none. Aliases are compared as the record
  # stores them, so two spelled apart only by spaces are namesakes, and the
  # objects with no alias are namesakes of each other.
  def namesake_indexes(list)
    (@namesake_indexes ||= {})[list] ||= begin
      @record.fetch(list).group_by { _1['alias'].to_s.unicode_normalize(:nfc).gsub(/[[:space:]]+/, ' ').gsub(/\A | \z/, '') }.each_value.with_object({}.compare_by_identity) {|namesakes, indexes|
        namesakes.each_with_index do |object, index|
          indexes[object] = (index if namesakes.size > 1)
        end
      }
    end
  end

  # The record's name for an SRA object type: the singular of the list its
  # objects are in (STUDY → "project").
  def kind_name(value, path)
    kind = Mapping::ROOTS.fetch(value.strip) { raise Unmapped, "#{path}: #{value.inspect} is not an SRA object type" }

    ROOT_LISTS.dig(kind, 1) || kind
  end

  # The value as the schema types it. XML Schema lets such values stand
  # between spaces; a number is read only in its decimal notation, and one
  # the record cannot hold as it was written (past 2^53, overflowing, or
  # underflowing to zero) is refused rather than changed.
  def cast(place, value, path)
    type = Schema.type_at(place)

    cast =
      case type
      when 'integer' then integer(value.strip)
      when 'number'  then number(value.strip)
      when 'boolean' then BOOLEANS[value.strip]
      else                value
      end

    cast.nil? ? raise(Unmapped, "#{path}: #{value.inspect} is not a #{type}") : cast
  end

  def integer(text)
    Integer(text, 10).then { _1 if _1.abs <= SAFE_MAX } if text.match?(INTEGER)
  end

  def number(text)
    return unless text.match?(NUMBER)

    Float(text).then { _1 if _1.finite? && (_1.nonzero? || !text[/\A[^eE]*/].match?(/[1-9]/)) }
  end

  # Elements of lists that nothing was written into carry nothing. A
  # document's own object is left for #call to refuse, not dropped, and the
  # pruning is in place, since relations hold the objects they are resolved
  # against.
  def prune(value)
    case value
    when Hash  then value.each_value { prune(_1) }.delete_if { prunable?(_2) }
    when Array then value.each { prune(_1) }.delete_if { prunable?(_1) }
    end
  end

  def prunable?(value) = (value.is_a?(Hash) || value.is_a?(Array)) && value.empty? && !@roots.key?(value)
end
