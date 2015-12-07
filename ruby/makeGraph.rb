require_relative 'classes'
require_relative 'constants'

require_relative 'builders/logic_builder'
require_relative 'builders/inline_builder'
require_relative 'builders/element_builder'

class Grapher
  include LanguageDefinition

  BUILDERS = [
    SpecialTextBuilder,
    InlineBuilder,
    ElementBuilder,
    LogicBuilder,
  ]

  def self.find_builder(line)
    builder = BUILDERS
      .lazy
      .map{ |builder_class| builder_class.new(line) }
      .find{ |builder| builder.matches? }
    line.assert(!builder.nil?, 'Line did not match any builder')
    builder
  end

  def self.call_builder(builder, *args)
    cps_args = builder.run(*args)
    builder.assert(cps_args.length == 2, "Builder method returning bad array.")
    cps_args
  end

  def self.make_graph(lines, accumulator = [])
    return accumulator if lines.length == 0
    line, *tail = lines
    make_graph(*call_builder(find_builder(line), tail, accumulator))
  end
end
