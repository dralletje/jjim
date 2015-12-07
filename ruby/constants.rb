module LanguageDefinition
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

  EMBEDDED = ['javascript']

  REGULAR_EXPRESSIONS = OpenStruct.new({
    match_element: /^([a-z#.][^ :]*) *([|= ]|==|$)((?: *[^ ]+)*)$/i,
    match_inline: /^([^: ]+): *(.*)/,
    match_logic: /^- (.*)/,
    match_special_text: /^(\||==?) *(.*)/,

    tag_or_class_or_id: /(?:[a-z]+)|(?:#[a-z0-9-]+)|(?:\.[a-z0-9-]+)/i,
    attribute: /^([a-z]+)=[^ ]/i,
  })
end
