import {expect} from 'chai'

import child_process from 'child_process'

import {graph} from '../'

const h = (
  tag = 'div',
  props = {},
  children = []
) => {
  return {
    type: 'HTMLElement',
    payload: {
      tag, props, children
    },
  }
}

const text = text => ({
  type: 'Text',
  payload: text,
})

const variable = (code, escaped = true) => ({
  type: 'Variable',
  payload: { code, escaped },
})

const condition = (type, payload = null, children = []) => {
  return {
    type: 'Logic',
    payload: {
      type, payload, children,
    },
  }
}

const block = (type, block) => {
  return {
    type: 'Block',
    payload: {
      type, block,
    },
  }
}

const tests = (expectGraph) => {
  describe('tags', () => {
    it('should compile simple examples', () => {
      expectGraph(`div`).equals(
        h('div')
      )
      expectGraph(`.container`).equals(
        h('div', {className: '"container"'})
      )
      expectGraph(`#myapp`).equals(
        h('div', {id: '"myapp"'})
      )
      expectGraph(`ul`).equals(
        h('ul')
      )
      expectGraph(`li.container#myApp`).equals(
        h('li', {
          className: '"container"',
          id: '"myApp"',
        })
      )
    })

    it('should support nested elements', () => {
      expectGraph(`
        ul
          li One
          li Two
      `).equals(
        h('ul', {}, [
          h('li', {}, [
            text('One'),
          ]),
          h('li', {}, [
            text('Two'),
          ]),
        ])
      )
    })

    it('should support inline nested elements', () => {
      expectGraph(`a: strong A strong link`).equals(
        h('a', {}, [
          h('strong', {}, [
            text('A strong link'),
          ]),
        ])
      )
    })

    it('should support deep nested elements', () => {
      expectGraph(`
        #app
          .container
            .column
      `).equals(
        h('div', {id: '"app"'}, [
          h('div', {className: '"container"'}, [
            h('div', {className: '"column"'})
          ]),
        ])
      )
    })
  })

  describe('attributes', () => {
    it('should accept simple string attributes', () => {
      expectGraph(`div id="myApp"`).equals(
        h('div', {id: '"myApp"'})
      )
    })

    it('should accept code attributes', () => {
      expectGraph(`div onclick=myHandler`).equals(
        h('div', {onclick: 'myHandler'})
      )
    })

    it.skip('should allow spaces in attributes', () => {
      expectGraph(`div id = "myApp"`).equals(
        h('div', {id: '"myApp"'})
      )
      expectGraph(`div onclick = myHandler`).equals(
        h('div', {onclick: 'myHandler'})
      )
    })

    it.skip('should allow attributes to be wrapped', () => {
      expectGraph(`div (id = "myApp")`).equals(
        h('div', {id: '"myApp"'})
      )
      expectGraph(`div [onclick = myHandler]`).equals(
        h('div', {onclick: 'myHandler'})
      )
      expectGraph(`div {onclick=myHandler}`).equals(
        h('div', {onclick: 'myHandler'})
      )
    })

    it.skip('should allow wrapped attributes directly after tag', () => {
      expectGraph(`div(id="myApp")`).equals(
        h('div', {id: '"myApp"'})
      )
    })

    it.skip('should allow multiline wrapped attributes', () => {
      expectGraph(`
        div(id="myApp"
            name="something else")
      `).equals(
        h('div', {id: '"myApp"', name: '"something else"'})
      )
    })
  })

  describe('conditions -', () => {
    it('should support if conditions', () => {
      expectGraph(`
        - if array.any?
          span Just some text
      `).equals(
        condition('if', { predicate: 'array.any?' }, [
          h('span', {}, [ text('Just some text') ]),
        ])
      )
    })

    it('should support for ... in ... loops', () => {
      expectGraph(`
        - for post in posts
          span = post
      `).equals(
        condition('for', {item: 'post', collection: 'posts'}, [
          h('span', {}, [ variable('post') ]),
        ])
      )
    })

    it('should support - if ... - else .... conditions', () => {
      expectGraph(`
        - if unread.any?
          span You got unread mail!
        - else
          span No unread mail :(
      `).equals(
        condition('if', {
          predicate: 'unread.any?',
          else: [
            h('span', {}, [ text('No unread mail :(') ])
          ],
        }, [
          h('span', {}, [ text('You got unread mail!') ])
        ])
      )
    })
  })

  describe('= and ==', () => {
    it('should allow = after tags', () => {
      expectGraph(`span = my_fn()`).equals(
        h('span', {}, [
          variable('my_fn()'),
        ])
      )
    })

    it('should allow == after tags', () => {
      expectGraph(`span == my_fn()`).equals(
        h('span', {}, [
          variable('my_fn()', false),
        ])
      )
    })

    it('should allow = standalone', () => {
      expectGraph(`
        span
          = my_fn()
      `).equals(
        h('span', {}, [
          variable('my_fn()'),
        ])
      )
    })

    it('should allow == standalone', () => {
      expectGraph(`
        span
          == my_fn()
      `).equals(
        h('span', {}, [
          variable('my_fn()', false),
        ])
      )
    })
  })

  describe('|', () => {
    it('should work inline without |', () => {
      expectGraph(`span Hi there`).equals(
        h('span', {}, [
          text('Hi there'),
        ])
      )
    })

    it('should work inline', () => {
      expectGraph(`span | Hi there`).equals(
        h('span', {}, [
          text('Hi there'),
        ])
      )
    })

    it('should work standalone', () => {
      expectGraph(`
        span
          | Hi there
      `).equals(
        h('span', {}, [
          text('Hi there'),
        ])
      )
    })
  })

  describe('Embedded renderer:', () => {
    it('should capture a javascript block', () => {
      expectGraph(`
        javascript:
          alert('hi')
      `).equals(
        block('javascript', [`alert('hi')`])
      )
    })

    it('should capture inline javascript', () => {
      expectGraph(`javascript: alert('hi')`).equals(
        block('javascript', [`alert('hi')`])
      )
    })

    it('should capture multiline javascript block', () => {
      expectGraph(`
        javascript:
          alert('hi')
          alert('boo')
      `).equals(
        block('javascript', [`alert('hi')`, `alert('boo')`])
      )
    })

    it('should capture multiline (indented) javascript block', () => {
      expectGraph(`
        javascript:
          if (false) {
            alert('Something went wrong...')
          }
      `).equals(
        block('javascript', [
          `if (false) {`,
          `  alert('Something went wrong...')`,
          `}`,
        ])
      )
    })
  })
}

describe('Ruby compile', () => {
  const expectGraph = code => ({
    equals: toBe => {
      // Run the ruby compiler,
      // Pass code into it and pipe stderr to console
      try {
        const raw_result = child_process.execSync('ruby ./cli.rb', {
          input: code,
          stdio: [null, null, process.stdout],
        })
        const result = JSON.parse(raw_result.toString())
        expect(result[0]).to.eql(toBe)
      } catch (e) {
        throw e
      }
    }
  })
  tests(expectGraph)
})

describe('JS compile', () => {
  const expectGraph = code => ({
    equals: toBe => {
      const result = graph(code)
      expect(result[0]).to.eql(toBe)
    }
  })
  tests(expectGraph)
})
