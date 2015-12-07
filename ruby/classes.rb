require 'ostruct'

class Indentation
  def initialize(line)
    without_indent = line.gsub(/^ */, '')

    @indentation = line.length - without_indent.length
    @line = without_indent
  end

  def line
    @line
  end

  def indentation
    @indentation
  end
end

class Line
  attr_reader :line
  attr_reader :child_lines

  def initialize(line, child_lines = [])
    @line = line
    @child_lines = child_lines
  end

  def nested_children
    first_line, *tail = @child_lines
    tail.take_while do |line|
      line.indentation > first_line.indentation
    end
  end

  def next_lines
    first_line, *tail = @child_lines
    tail.drop_while do |line|
      line.indentation > first_line.indentation
    end
  end

  # Create nested object
  def get_children
    if @child_lines.first.nil?
      []
    else
      [Line.new(@child_lines.first.line, nested_children)] + Line.new('', next_lines).get_children
    end
  end

  def get_block
    next_line = @child_lines.first
    @child_lines.map do |child|
      (' ' * (child.indentation - next_line.indentation)) + child.line
    end
  end
end

class Node
  attr_reader :type
  attr_reader :payload

  @@types = [
    :HTMLElement,
    :Logic,
    :Text,
    :Variable,
    :Block,
  ]

  # Add constants for them all!
  @@types.each do |type|
    self.class_eval("def self.#{type.upcase}; :#{type} ;end")
  end

  # Create more ruby_ish constant for HTMLElement 😁
  def self.HTML_ELEMENT
    :HTMLElement
  end

  def initialize(type, payload)
    Grapher.assert(@@types.include?(type), "Unknown type '#{type}'")

    @type = type
    @payload = payload
  end

  def to_json(*opts)
    {type: @type.to_s, payload: @payload}.to_json(*opts)
  end
end
