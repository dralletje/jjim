import _ from 'lodash'

// EDIT THE RegExp.test METHOD!!!
const regexpTest = regexp => subject => regexp.test(subject)

const assert = (pred, msg) => {
  if (!pred) {
    throw new Error(msg)
  }
}

const debug = (...args) => {
  console.error(...args)
}

const match = (regexp, subject) =>{
  const localMatch = subject.match(regexp)
  return localMatch === null ? localMatch : localMatch.slice(1)
}

const EMBEDDED = ['javascript']

const splitAt = (array, predicate) => {
  const _index = array.findIndex(x => !predicate(x))
  const index = _index === -1 ? Infinity : _index

  return [
    array.slice(0, index),
    array.slice(index)
  ]
}

const makeNode = (type, payload) => ({type, payload})

const types = {
  HTMLElement: 'HTMLElement',
  Logic: 'Logic',
  Text: 'Text',
  Variable: 'Variable',
  Block: 'Block',
}

const regexp = {
  matchElement: /^([a-z#.][^ :]*) *([|= ]|==|$)((?: *[^ ]+)*)$/i,
  matchInline: /^([^: ]+): *(.*)/,
  tagOrClassOrId: /(?:[a-z]+)|(?:#[a-z0-9-]+)|(?:\.[a-z0-9-]+)/ig,
  attribute: /([a-z]+)=[^ ]/i,

  matchLogic: /^- (.*)/,

  matchSpecialText: /^(\||==?) *(.*)/,
}

const makeTextNode = node => {
  assert(node.getChildren().length !== [], 'A text node can\'t have any children')

  const match = node.line.match(regexp.matchSpecialText)
  const [operator, text] =
    match !== null
    ? match.slice(1) : ['|', node.line]

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
      node.getChildren.length === 0,
      `No please, don't give text any children!`
    )
    return [makeTextNode(node)].concat(next(tail))
  }
}, {
  regexp: regexp.matchInline,
  handler: (node, tail, next) => {
    const [tag, rest] = node.line.match(regexp.matchInline).slice(1)
    // It's an embedder
    if (EMBEDDED.indexOf(tag) !== -1) {
      return [makeNode(types.Block, {
        type: tag,
        block: (rest === '' ? [] : [rest]).concat(node.getBlock())
      })].concat(next(tail))
    } else { // It's an embedded tag
      assert(rest !== '', 'inline tag without content')

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

    const [attributes, text] = splitAt(args, regexpTest(regexp.attribute))
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
      .concat(id === '' ? [] : [['id', `"${id}"`]])
      .concat(className === '' ? [] : [['className', `"${className}"`]])

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
    const withoutPrefix = node.line.match(regexp.matchLogic)[1]
    const [command, ...args] =
      withoutPrefix.split(' ')
      .filter(x => x !== '')

    if (command === 'if') {
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

    if (command === 'for') {
      const [item, _in_, collection, ...tooMuch] = args

      assert(
        _in_ === 'in' && tooMuch.length === 0,
        `Malformed for loop (${node.line})`
      )

      return [makeNode(types.Logic, {
        type: 'for',
        payload: { item, collection },
        children: next(node.getChildren()),
      })].concat(next(tail))
    }

    assert(command !== 'else', `Else condition without a if statement in front! D:`)
    assert(false, `Unsupported condition '${node.line}'`)
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
  if (nodes.length === 0) {
    return []
  }

  const [node, ...tail] = nodes

  const matcher = matchers.find( ({regexp}) => regexp.test(node.line))

  //assert(matcher !== undefined, 'Weird things')
  if (matcher === undefined) {
    return [{
      type: 'UNKNOWN',
      payload: node.line,
    }].concat(graphToReact(tail))
  }

  //const match = line.line.match(matcher.regexp).slice(1);

  return matcher.handler(node, tail, graphToReact)
}

export default graphToReact
