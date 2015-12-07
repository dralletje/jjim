require_relative 'builder'

require 'pp'

# Conditions like - if ... - else ...
class InlineBuilder < Builder
  def initialize(*args)
    @REGEXP = REGULAR_EXPRESSIONS.match_inline
    super(*args)
  end

  def as_embedded(tail, accumulator)
    tag, text = @match
    [tail, accumulator + [@line.to_node(Node.BLOCK, {
      type: tag,
      block: (text == '' ? [] : [text]).concat(@line.get_block())
    })]]
  end

  def as_inline(tail, accumulator)
    tag, text = @match
    assert(text != '', 'Inline tag without content')
    [ [Line.new(tag, [Indentation.new(text)] + @line.child_lines)] + tail,
      accumulator ]
  end

  def run(tail, accumulator)
    if EMBEDDED.include? @match.first
    then as_embedded(tail, accumulator)
    else as_inline(tail, accumulator)
    end
  end
end

# Conditions like - if ... - else ...
class SpecialTextBuilder < Builder
  def initialize(*args)
    @REGEXP = REGULAR_EXPRESSIONS.match_special_text
    super(*args)
  end

  def run(tail, accumulator)
    assert(!@line.has_children?, "No please, don't give text any children!")
    return [tail, accumulator + [make_text_node(@line)]]
  end
end
