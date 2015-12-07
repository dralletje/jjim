module LanguageDefinition
  def self.match(regexp, string)
    regexp.match(string).to_a.slice(1..-1)
  end

  TAG_NAME_PARSERS = {
    '#' => :id,
    '.' => :class_name,
    :otherwise => :tag,
  }

  TEXT_NODE_CREATORS = {
    '|' => lambda do |payload, make_node|
      make_node.call(Node.TEXT, payload)
    end,

    '=' => lambda do |payload, make_node|
      make_node.call(Node.VARIABLE, {
        code: payload,
        escaped: true,
      })
    end,

    '==' => lambda do |payload, make_node|
      make_node.call(Node.VARIABLE, {
        code: payload,
        escaped: false,
      })
    end,
  }

  LOGIC_NODE_CREATOR = {
    if: lambda do |line, predicate, tail|
      _else_, *without_else = tail

      if (_else_ && /^- *?else *$/ =~ _else_.line)
        return [without_else, line.to_node(Node.LOGIC, {
          type: 'if',
          payload: {
            predicate: predicate,
            else: _else_.graph,
          },
          children: line.graph,
        })]
      else
        return [tail, line.to_node(Node.LOGIC, {
          type: 'if',
          payload: { predicate: predicate },
          children: line.graph,
        })]
      end
    end,

    for: lambda do |line, query, tail|
      for_in_regexp = /^ *([a-zA-Z][a-zA-Z0-9_]+) *in *([a-zA-Z][a-zA-Z0-9_]+) */
      for_in_match = match(for_in_regexp, query)

      line.assert(for_in_match.length == 2, "Malformed for loop")
      item, collection = for_in_match

      return [tail, line.to_node(Node.LOGIC, {
        type: 'for',
        payload: { item: item, collection: collection },
        children: line.graph,
      })]
    end,
  }

  EMBEDDED = ['javascript']

  TAG_SIGNS = TAG_NAME_PARSERS.keys.reject{ |x| x == :otherwise }.map(&:to_s).join
  REGULAR_EXPRESSIONS = OpenStruct.new({
    match_element: /^([a-z#.][^ :]*) *([|= ]|==|$)((?: *[^ ]+)*)$/i,
    match_inline: /^([^: ]+): *(.*)/,
    match_logic: /^- *([a-z]+) *(.*)/,
    match_special_text: /^(\||==?) *(.*)/,

    #tag_or_class_or_id: /(?:[a-z0-9_-]+)|(?:#[a-z0-9_-]+)|(?:\.[a-z0-9_-]+)/i,
    tag_or_class_or_id: /[#{TAG_SIGNS}]?[^#{TAG_SIGNS}]+/i,
    attribute: /^([a-z]+)=[^ ]/i,
  })
end
