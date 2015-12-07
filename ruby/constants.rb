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
    matchElement: /^([a-z#.][^ :]*) *([|= ]|==|$)((?: *[^ ]+)*)$/i,
    matchInline: /^([^: ]+): *(.*)/,
    tagOrClassOrId: /(?:[a-z]+)|(?:#[a-z0-9-]+)|(?:\.[a-z0-9-]+)/i,
    attribute: /^([a-z]+)=[^ ]/i,

    matchLogic: /^- (.*)/,

    matchSpecialText: /^(\||==?) *(.*)/,
  })
end
