module LanguageDefinition
  def self.match(regexp, string)
    regexp.match(string).to_a.slice(1..-1)
  end

  def self.assert(pred, msg)
    if not pred
      raise Exception.new(msg)
    end
  end

  TEXT_NODE_CREATORS = {
    '|' => lambda do |payload|
      Node.new(Node.TEXT, payload)
    end,

    '=' => lambda do |payload|
      Node.new(Node.VARIABLE, {
        code: payload,
        escaped: true,
      })
    end,

    '==' => lambda do |payload|
      Node.new(Node.VARIABLE, {
        code: payload,
        escaped: false,
      })
    end,
  }

  LOGIC_NODE_CREATOR = {
    if: lambda do |node, predicate, tail|
      _else_, *without_else = tail

      if (_else_ && /^- *?else *$/ =~ _else_.line)
        return [without_else, Node.new(Node.LOGIC, {
          type: 'if',
          payload: {
            predicate: predicate,
            else: _else_.graph,
          },
          children: node.graph,
        })]
      else
        return [tail, Node.new(Node.LOGIC, {
          type: 'if',
          payload: { predicate: predicate },
          children: node.graph,
        })]
      end
    end,

    for: lambda do |node, query, tail|
      for_in_regexp = /^ *([a-zA-Z][a-zA-Z0-9_]+) *in *([a-zA-Z][a-zA-Z0-9_]+) */
      for_in_match = match(for_in_regexp, query)

      assert(for_in_match.length == 2, "Malformed for loop (#{node.line})")
      item, collection = for_in_match

      return [tail, Node.new(Node.LOGIC, {
        type: 'for',
        payload: { item: item, collection: collection },
        children: node.graph,
      })]
    end,
  }

  EMBEDDED = ['javascript']

  REGULAR_EXPRESSIONS = OpenStruct.new({
    match_element: /^([a-z#.][^ :]*) *([|= ]|==|$)((?: *[^ ]+)*)$/i,
    match_inline: /^([^: ]+): *(.*)/,
    match_logic: /^- *([a-z]+) *(.*)/,
    match_special_text: /^(\||==?) *(.*)/,

    tag_or_class_or_id: /(?:[a-z]+)|(?:#[a-z0-9-]+)|(?:\.[a-z0-9-]+)/i,
    attribute: /^([a-z]+)=[^ ]/i,
  })
end
