require_relative 'builder'

# Conditions like - if ... - else ...
class ElementBuilder < Builder
  IS_ATTRIBUTE = lambda { |x| x =~ REGULAR_EXPRESSIONS.attribute }
  GET_TAIL = lambda { |x| x.slice(1..-1) }

  def hash_get(hash, key)
    assert(hash.include?(key), 'Looking for a weird character in tag')
    hash[key]
  end

  def initialize(*args)
    @REGEXP = REGULAR_EXPRESSIONS.match_element
    super(*args)
  end

  def tag_attributes
    @match.first
    .scan(REGULAR_EXPRESSIONS.class_or_id)
    .group_by{ |x| hash_get(TAG_NAME_PARSERS, x[0]) }
    .map{ |key, value| [key.to_s, "\"#{value.map(&GET_TAIL).join(' ')}\""] }
  end

  def attributes
    @match[1].split(' ')
    .take_while(&IS_ATTRIBUTE)
    .map{ |x| match(/(.*)=(.*)/, x) }
  end

  def children
    text = @match[1].split(' ').drop_while(&IS_ATTRIBUTE).reject(&:empty?).join(' ')
    if text.empty?
    then @line.graph
    else  [make_text_node(Line.new(text))] + @line.get_children.map(&method(:make_text_node))
    end
  end

  def tag
    (match(REGULAR_EXPRESSIONS.tag, @match.first) || ['div'])[0]
  end

  def new_node
    @line.to_node(Node.HTML_ELEMENT, {
      tag: tag,
      props: (attributes + tag_attributes).to_h,
      children: children,
    })
  end

  def run(tail, accumulator)
    [
      tail,
      accumulator + [new_node]
    ]
  end
end
