// Utils that are 'shared' between the javascript
// and ruby version, to make them more alike
import _ from 'lodash'

export const assert = (pred, msg) => {
  if (!pred) {
    throw new Error(msg)
  }
}

export const does_match = (regexp, subject) => regexp.test(subject)

export const debug = (...args) => {
  console.error(...args)
}

export const regexpmatch = (regexp, subject) =>{
  const localMatch = subject.match(regexp)
  return localMatch === null ? localMatch : localMatch.slice(1)
}

export const splitAt = (array, predicate) => {
  const _index = array.findIndex(x => !predicate(x))
  const index = _index === -1 ? Infinity : _index

  return [
    array.slice(0, index),
    array.slice(index)
  ]
}

export const types = {
  HTMLElement: 'HTMLElement',
  Logic: 'Logic',
  Text: 'Text',
  Variable: 'Variable',
  Block: 'Block',
}
