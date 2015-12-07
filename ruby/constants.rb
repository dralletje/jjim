module LanguageDefinition
  TEXT_NODE_TYPES = {
    '|' => -> (payload) do
      Node.new(:Text, payload)
    end,
    '=' => -> (payload) do
      Node.new(:Variable, {
        code: payload,
        escaped: true,
      })
    end,
    '==' => -> (payload) do
      Node.new(:Variable, {
        code: payload,
        escaped: false,
      })
    end,
  }

  REGULAR_EXPRESSIONS = OpenStruct.new({
    matchElement: /^([a-z#.][^ :]*) *([|= ]|==|$)((?: *[^ ]+)*)$/i,
    matchInline: /^([^: ]+): *(.*)/,
    tagOrClassOrId: /(?:[a-z]+)|(?:#[a-z0-9-]+)|(?:\.[a-z0-9-]+)/i,
    attribute: /^([a-z]+)=[^ ]/i,

    matchLogic: /^- (.*)/,

    matchSpecialText: /^(\||==?) *(.*)/,
  })
end
