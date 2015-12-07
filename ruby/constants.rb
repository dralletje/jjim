module LanguageDefinition
  TAG_NAME_PARSERS = {
    '#' => :id,
    '.' => :className,
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

  EMBEDDED = ['javascript']

  TAG_SIGNS = TAG_NAME_PARSERS.keys.reject{ |x| x == :otherwise }.map(&:to_s).join
  REGULAR_EXPRESSIONS = OpenStruct.new({
    match_element: /^([a-z#.][^ :]*) *((?: *[^ ]+)*)$/i,
    match_inline: /^([^: ]+): *(.*)/,
    match_logic: /^- *([a-z]+) *(.*)/,
    match_special_text: /^(\||==?) *(.*)/,

    #tag_or_class_or_id: /(?:[a-z0-9_-]+)|(?:#[a-z0-9_-]+)|(?:\.[a-z0-9_-]+)/i,
    tag: /^([^#{TAG_SIGNS}]+)/,
    class_or_id: /[#{TAG_SIGNS}][^#{TAG_SIGNS}]+/i,
    attribute: /^([a-z]+)=[^ ]/i,
  })
end
