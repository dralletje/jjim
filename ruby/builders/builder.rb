class Builder
  include LanguageDefinition

  def initialize(line)
    @line = line
    @match = match(@REGEXP, line.line)
  end

  # Util functions
  def self.debug(arg)
    STDERR.puts(PP.pp(arg, ""))
  end

  def match(regexp, string)
    regexp.match(string).to_a.slice(1..-1)
  end

  def make_text_node(line)
    line.assert(line.get_children.length == 0, 'A text node can\'t have any children')

    special_text = match(REGULAR_EXPRESSIONS.match_special_text, line.line)
    operator, text = (special_text or ['|', line.line])
    TEXT_NODE_CREATORS[operator].call(text, line.method(:to_node))
  end

  # Instance methods
  def matches?
    !@match.nil?
  end

  def assert(*args)
    @line.assert(*args)
  end


  def run(tail, accumulator)
    handle_line(@line, tail, accumulator)
  end
end
