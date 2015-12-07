import _ from 'lodash'

import {
  assert, splitAt, debug,
  regexpmatch, does_match, types,
} from './utils'

const EMBEDDED = ['javascript']

const makeNode = (type, payload) => ({type, payload})

const regexp = {
  matchElement: /^([a-z#.][^ :]*) *([|= ]|==|$)((?: *[^ ]+)*)$/i,
  matchInline: /^([^: ]+): *(.*)/,
  tagOrClassOrId: /(?:[a-z]+)|(?:#[a-z0-9-]+)|(?:\.[a-z0-9-]+)/ig,
  attribute: /([a-z]+)=[^ ]/i,

  matchLogic: /^- (.*)/,

  matchSpecialText: /^(\||==?) *(.*)/,
}

const makeTextNode = node => {
  assert(node.getChildren().length !== [], 'A text node can\'t have any children', node)

  const match = regexpmatch(regexp.matchSpecialText, node.line)
  const [operator, text] = match || ['|', node.line]

  switch (operator) {
  case '|':
    return makeNode(types.Text, text)
  case '=':
    return makeNode(types.Variable, {
      code: text,
      escaped: true,
    })
  case '==':
    return makeNode(types.Variable, {
      code: text,
      escaped: false,
    })
  }
}

const matchers = [{
  regexp: regexp.matchSpecialText,
  handler: (node, tail, next) => {
    assert(
      node.getChildren.length == 0,
      `No please, don't give text any children!`,
      node
    )
    return [makeTextNode(node)].concat(next(tail))
  }
}, {
  regexp: regexp.matchInline,
  handler: (node, tail, next) => {
    const [tag, rest] = regexpmatch(regexp.matchInline, node.line)
    // It's an embedder
    if (EMBEDDED.indexOf(tag) !== -1) {
      return [makeNode(types.Block, {
        type: tag,
        block: (rest == '' ? [] : [rest]).concat(node.getBlock())
      })].concat(next(tail))
    } else { // It's an embedded tag
      assert(rest !== '', `After a inline colon you need content!`, node)

      return next([{
        line: tag,
        getChildren: () =>
          [{
            line: rest,
            getChildren: () => [],
            getBlock: () => [],
          }].concat(node.getChildren()),
        getBlock: () => [node.line].concat(node.getBlock()),
      }].concat(tail))
    }
  }
}, {
  // Html tags like tag, .class, #id and mixes of those
  regexp: regexp.matchElement,
  handler: (node, tail, next) => {
    const [tag, ...args] = node.line.split(' ')

    const info = Object.assign(
      {id: [], className: [], tag: []},
      _.groupBy(tag.match(regexp.tagOrClassOrId), match => {
        switch (match[0]) {
        case '#':
          return 'id'
        case '.':
          return 'className'
        default:
          return 'tag'
        }
      })
    )

    const [attributes, text] = splitAt(args, (subject) => does_match(regexp.attribute, subject))
    const attributes2 = attributes.map(x => x.split('='))

    const hasText = text.length !== 0

    const newChildren =
      hasText
      ? [makeTextNode({line: text.join(' '), getChildren: () => []})]
        .concat(node.getChildren().map(makeTextNode))
      : next(node.getChildren())

    const id = info.id.map(x => x.slice(1)).join(' ')
    const className = info.className.map(x => x.slice(1)).join(' ')
    const props =
      attributes2
      .concat(id == '' ? [] : [['id', `"${id}"`]])
      .concat(className == '' ? [] : [['className', `"${className}"`]])

    return [makeNode(types.HTMLElement, {
      tag: info.tag[0] || 'div',
      props: _.zipObject(props),
      children: newChildren,
    })].concat(next(tail))
  },
}, {
  // Conditions like - if ... - else ...
  regexp: regexp.matchLogic,
  handler: (node, tail, next) => {
    const withoutPrefix = regexpmatch(regexp.matchLogic, node.line)[0]
    const [command, ...args] =
      withoutPrefix.split(' ')
      .filter(x => x !== '')

    if (command == 'if') {
      const [_else_, ...withoutElse] = tail

      if (_else_ && /^- *?else */.test(_else_.line)) {
        return [makeNode(types.Logic, {
          type: 'if',
          payload: {
            predicate: withoutPrefix.match(/^if ?(.*)/)[1],
            else: next(_else_.getChildren())
          },
          children: next(node.getChildren()),
        })].concat(next(withoutElse))
      } else {
        return [makeNode(types.Logic, {
          type: 'if',
          payload: {
            predicate: withoutPrefix.match(/^if ?(.*)/)[1],
          },
          children: next(node.getChildren()),
        })].concat(next(tail))
      }
    }

    if (command == 'for') {
      const [item, _in_, collection, ...tooMuch] = args

      assert(
        _in_ == 'in' && tooMuch.length == 0,
        `Malformed for loop (${node.line})`,
        node
      )

      return [makeNode(types.Logic, {
        type: 'for',
        payload: { item, collection },
        children: next(node.getChildren()),
      })].concat(next(tail))
    }

    assert(command !== 'else', `Else condition without a if statement in front! D:`, node)
    assert(false, `Unsupported condition '${node.line}'`, node)
  }
}]
// }, {
//   // Conditions like - if ... - else ...
//   regexp: /^\$/,
//   handler: (line, children) => {
//     return [{
//       type: 'ATTR',
//       payload: {
//         line: 'ng-' + line.slice(1),
//         children: [],
//       }
//     }]
//   }
// }, {
//   // Conditions like - if ... - else ...
//   regexp: /^\@/,
//   handler: (line, children) => {
//     return [{
//       type: 'ATTR',
//       payload: {
//         line: line.slice(1),
//         children: [],
//       }
//     }]
//   }
// }]


const graphToReact = nodes => {
  if (nodes.length == 0) {
    return []
  }

  const [node, ...tail] = nodes

  const matcher = matchers.find( ({regexp}) => regexp.test(node.line))

  //assert(matcher !== undefined, 'Weird things')
  if (matcher == undefined) {
    return [{
      type: 'UNKNOWN',
      payload: node.line,
    }].concat(graphToReact(tail))
  }

  //const match = line.line.match(matcher.regexp).slice(1);

  return matcher.handler(node, tail, graphToReact)
}

export default graphToReact
