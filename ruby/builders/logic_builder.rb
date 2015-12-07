require_relative 'builder'

# Conditions like - if ... - else ...
class LogicBuilder < Builder
  def self.match(regexp, string)
    regexp.match(string).to_a.slice(1..-1)
  end

  LOGIC_NODE_CREATOR = {
    if: lambda do |predicate, tail|
      _else_, *without_else = tail

      if (_else_ && /^- *?else *$/ =~ _else_.line)
        return [without_else, @line.to_node(Node.LOGIC, {
          type: 'if',
          payload: {
            predicate: predicate,
            else: _else_.graph,
          },
          children: @line.graph,
        })]
      else
        return [tail, @line.to_node(Node.LOGIC, {
          type: 'if',
          payload: { predicate: predicate },
          children: @line.graph,
        })]
      end
    end,

    for: lambda do |query, tail|
      for_in_regexp = /^ *([a-zA-Z][a-zA-Z0-9_]+) *in *([a-zA-Z][a-zA-Z0-9_]+) */
      for_in_match = match(for_in_regexp, query)

      assert(for_in_match.length == 2, "Malformed for loop")
      item, collection = for_in_match

      return [tail, @line.to_node(Node.LOGIC, {
        type: 'for',
        payload: { item: item, collection: collection },
        children: @line.graph,
      })]
    end,
  }

  def initialize(*args)
    @REGEXP = REGULAR_EXPRESSIONS.match_logic
    super(*args)
  end

  def get_logic_builder
    type = @match.first.to_sym
    assert(type != :else, "Else condition without a if statement in front! D:")
    assert(LOGIC_NODE_CREATOR.include?(type), "Unsupported condition")
    LOGIC_NODE_CREATOR[type]
  end

  def run(tail, accumulator)
    query = @match[1]
    new_tail, new_node = instance_exec(query, tail, &get_logic_builder)
    [new_tail, accumulator + [new_node]]
  end
end
