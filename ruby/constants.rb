module LanguageDefinition
      Node.new(:Text, payload)
  TEXT_NODE_CREATORS = {
    '|' => lambda do |payload|
    end,
      Node.new(:Variable, {
    '=' => lambda do |payload|
        code: payload,
        escaped: true,
      })
    end,
      Node.new(:Variable, {
    '==' => lambda do |payload|
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
