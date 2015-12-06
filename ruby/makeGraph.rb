require_relative 'classes'
require 'ostruct'
require 'pp'

class Grapher
  def self.assert(pred, msg)
    if not pred
      raise Exception.new(msg)
    end
  end

  def self.debug(arg)
    STDERR.puts(PP.pp(arg, ""))
  end

  def self.match(regexp, string)
    regexp.match(string).to_a.slice(1..-1)
  end

  EMBEDDED = ['javascript']

  def self.splitAt(array, &predicate)
    [
      array.take_while(&predicate),
      array.drop_while(&predicate),
    ]
  end

  def self.makeNode(type, payload)
    Node.new(type, payload)
  end

  $regexp = OpenStruct.new({
    matchElement: /^([a-z#.][^ :]*) *([|= ]|==|$)((?: *[^ ]+)*)$/i,
    matchInline: /^([^: ]+): *(.*)/,
    tagOrClassOrId: /(?:[a-z]+)|(?:#[a-z0-9-]+)|(?:\.[a-z0-9-]+)/i,
    attribute: /^([a-z]+)=[^ ]/i,

    matchLogic: /^- (.*)/,

    matchSpecialText: /^(\||==?) *(.*)/,
  })

  def self.makeTextNode(node)
    assert(node.getChildren.length == 0, 'A text node can\'t have any children')

    specialText = match($regexp.matchSpecialText, node.line)
    operator, text = (specialText or ['|', node.line])

    case operator
    when '|'
      makeNode(:Text, text)
    when '='
      makeNode(:Variable, {
        code: text,
        escaped: true,
      })
    when '=='
      makeNode(:Variable, {
        code: text,
        escaped: false,
      })
    end
  end

  $matchers = [{
    regexp: $regexp.matchSpecialText,
    handler: lambda do |node, tail, accumulator|
      assert(
        node.getChildren.length === 0,
        "No please, don't give text any children!"
      )
      return [tail, accumulator + [makeTextNode(node)]]
    end,
  }, {
    regexp: $regexp.matchInline,
    handler: lambda do |node, tail, accumulator|
      tag, rest = match($regexp.matchInline, node.line)
      if EMBEDDED.include?(tag)
        return [tail, accumulator + [makeNode(:Block, {
          type: tag,
          block: (rest == '' ? [] : [rest]).concat(node.getBlock())
        })]]
      else # It's an embedded tag
        assert(rest != '', 'Inline tag without content')

        return [
          [Line.new(tag, [Indentation.new(rest)] + node.childLines)]+ tail,
          accumulator,
        ]
      end
    end,
  }, {
    # Html tags like tag, .class, #id and mixes of those
    regexp: $regexp.matchElement,
    handler: lambda do |node, tail, accumulator|
      tag, *args = node.line.split(' ')

      info = {id: [], className: [], tag: []}.merge(
        tag.scan($regexp.tagOrClassOrId).group_by do |match|
          case match[0]
          when '#' then :id
          when '.' then :className
          else :tag
          end
        end
      )

      attributes, text = splitAt(args) { |x| !(x =~ $regexp.attribute).nil? }
      attributes2 = attributes.map{ |x| x.split('=') }

      hasText = text.length != 0

      newChildren =
        if hasText
          [makeTextNode(Line.new(text.join(' ')))]
          .concat(node.getChildren().map(&method(:makeTextNode)))
        else
          makeGraph(node.getChildren())
        end

      get_tail = lambda { |x| x.slice(1..-1) }
      id = info[:id].map(&get_tail).join(' ')
      className = info[:className].map(&get_tail).join(' ')
      props =
        attributes2
        .concat(id == '' ? [] : [['id', "\"#{id}\""]])
        .concat(className == '' ? [] : [['className', "\"#{className}\""]])

      return [
        tail,
        accumulator + [makeNode(:HTMLElement, {
          tag: info[:tag][0] || 'div',
          props: props.to_h,
          children: newChildren,
        })]
      ]
    end,
  }, {
    # Conditions like - if ... - else ...
    regexp: $regexp.matchLogic,
    handler: lambda do |node, tail, accumulator|
      withoutPrefix = match($regexp.matchLogic, node.line).first
      command, *args =
        withoutPrefix.split(' ')
        .select{ |x| x != '' }

      if command == 'if'
        _else_, *withoutElse = tail
        predicate = match(/^if ?(.*)/, withoutPrefix).first

        if (_else_ && /^- *?else */ =~ _else_.line)
          return [withoutElse, accumulator + [makeNode(:Logic, {
            type: 'if',
            payload: {
              predicate: predicate,
              else: makeGraph(_else_.getChildren())
            },
            children: makeGraph(node.getChildren()),
          })]]
        else
          return [tail, accumulator + [makeNode(:Logic, {
            type: 'if',
            payload: {
              predicate: predicate,
            },
            children: makeGraph(node.getChildren()),
          })]]
        end
      end

      if command == 'for'
        item, _in_, collection, *tooMuch = args

        assert(
          _in_ == 'in' && tooMuch.length == 0,
          "Malformed for loop (#{node.line})"
        )

        return [tail, accumulator + [makeNode(:Logic, {
          type: 'for',
          payload: { item: item, collection: collection },
          children: makeGraph(node.getChildren()),
        })]]
      end

      assert(command != 'else', "Else condition without a if statement in front! D:")
      assert(false, "Unsupported condition '#{node.line}'")
    end,
  }]

  def self.makeGraph(nodes, accumulator = [])
    return accumulator if nodes.length == 0

    node, *rest = nodes

    matcher = $matchers.find{ |matcher| matcher[:regexp] =~ node.line }

    assert(!matcher.nil?, 'Line did not match anything')

    cps_args = matcher[:handler].call(node, rest, accumulator)
    assert(cps_args.length == 2, "Matcher method returning bad array.")
    makeGraph(*cps_args)
  end
end
