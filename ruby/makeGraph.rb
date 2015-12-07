require_relative 'classes'
require_relative 'constants'

require 'pp'

class Grapher
  include LanguageDefinition

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

  def self.split_at(array, &predicate)
    [
      array.take_while(&predicate),
      array.drop_while(&predicate),
    ]
  end

  def self.make_text_node(node)
    assert(node.get_children.length == 0, 'A text node can\'t have any children')

    special_text = match(REGULAR_EXPRESSIONS.match_special_text, node.line)
    operator, text = (special_text or ['|', node.line])

    TEXT_NODE_CREATORS[operator].call(text)
  end

  MATCHERS = [{
    regexp: REGULAR_EXPRESSIONS.match_special_text,
    handler: lambda do |node, tail, accumulator|
      assert(
        node.get_children.length === 0,
        "No please, don't give text any children!"
      )
      return [tail, accumulator + [make_text_node(node)]]
    end,
  }, {
    regexp: REGULAR_EXPRESSIONS.match_inline,
    handler: lambda do |node, tail, accumulator|
      tag, rest = match(REGULAR_EXPRESSIONS.match_inline, node.line)
      if EMBEDDED.include?(tag)
        return [tail, accumulator + [Node.new(Node.BLOCK, {
          type: tag,
          block: (rest == '' ? [] : [rest]).concat(node.get_block())
        })]]
      else # It's an embedded tag
        assert(rest != '', 'Inline tag without content')

        return [
          [Line.new(tag, [Indentation.new(rest)] + node.child_lines)]+ tail,
          accumulator,
        ]
      end
    end,
  }, {
    # Html tags like tag, .class, #id and mixes of those
    regexp: REGULAR_EXPRESSIONS.match_element,
    handler: lambda do |node, tail, accumulator|
      tag, *args = node.line.split(' ')

      info = {id: [], className: [], tag: []}.merge(
        tag.scan(REGULAR_EXPRESSIONS.tag_or_class_or_id).group_by do |match|
          case match[0]
          when '#' then :id
          when '.' then :className
          else :tag
          end
        end
      )

      attributes, text = split_at(args) { |x| !(x =~ REGULAR_EXPRESSIONS.attribute).nil? }
      attributes2 = attributes.map{ |x| x.split('=') }

      has_text = text.length != 0

      new_children =
        if has_text
          [make_text_node(Line.new(text.join(' ')))]
          .concat(node.get_children.map(&method(:make_text_node)))
        else
          make_graph(node.get_children)
        end

      get_tail = lambda { |x| x.slice(1..-1) }
      id = info[:id].map(&get_tail).join(' ')
      class_name = info[:className].map(&get_tail).join(' ')
      props =
        attributes2
        .concat(id == '' ? [] : [['id', "\"#{id}\""]])
        .concat(class_name == '' ? [] : [['className', "\"#{class_name}\""]])

      return [
        tail,
        accumulator + [Node.new(Node.HTML_ELEMENT, {
          tag: info[:tag][0] || 'div',
          props: props.to_h,
          children: new_children,
        })]
      ]
    end,
  }, {
    # Conditions like - if ... - else ...
    regexp: REGULAR_EXPRESSIONS.match_logic,
    handler: lambda do |node, tail, accumulator|
      without_prefix = match(REGULAR_EXPRESSIONS.match_logic, node.line).first
      command, *args =
        without_prefix.split(' ')
        .select{ |x| x != '' }

      if command == 'if'
        _else_, *without_else = tail
        predicate = match(/^if ?(.*)/, without_prefix).first

        if (_else_ && /^- *?else */ =~ _else_.line)
          return [without_else, accumulator + [Node.new(Node.LOGIC, {
            type: 'if',
            payload: {
              predicate: predicate,
            else: make_graph(_else_.get_children)
            },
            children: make_graph(node.get_children),
          })]]
        else
          return [tail, accumulator + [Node.new(Node.LOGIC, {
            type: 'if',
            payload: {
              predicate: predicate,
            },
            children: make_graph(node.get_children),
          })]]
        end
      end

      if command == 'for'
        item, _in_, collection, *too_much = args

        assert(
          _in_ == 'in' && too_much.length == 0,
          "Malformed for loop (#{node.line})"
        )

        return [tail, accumulator + [Node.new(Node.LOGIC, {
          type: 'for',
          payload: { item: item, collection: collection },
          children: make_graph(node.get_children),
        })]]
      end

      assert(command != 'else', "Else condition without a if statement in front! D:")
      assert(false, "Unsupported condition '#{node.line}'")
    end,
  }]

  def self.make_graph(nodes, accumulator = [])
    return accumulator if nodes.length == 0

    node, *rest = nodes

    matcher = MATCHERS.find{ |matcher| matcher[:regexp] =~ node.line }

    assert(!matcher.nil?, 'Line did not match anything')

    cps_args = matcher[:handler].call(node, rest, accumulator)
    assert(cps_args.length == 2, "Matcher method returning bad array.")
    make_graph(*cps_args)
  end
end
