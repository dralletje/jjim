import fs from 'fs'

import figureIndentation from './figureIndentation'
import makeGraph from './makeGraph'


export const graph = code => {
  const lines = code
    .split('\n')
    .filter(x => x.trim() !== '') // No empty lines
    .map(line => {
      const withoutIndent = line.replace(/^ */, '')
      return {
        indentation: line.length - withoutIndent.length,
        line: withoutIndent,
      }
    })

  if (lines.length === 0) {
    return makeGraph([], 0)
  } else {
    return makeGraph(figureIndentation(lines, lines[0].indentation))
  }
}

//console.log(JSON.stringify(graphToReact(graph), undefined, 4))
