import _ from 'lodash'

const assert = (pred, msg) => {
  if (!pred) {
    throw new Error(msg)
  }
}

const basicChild = {
  getChildren: () => [],
  getBlock: () => [],
}

// Create nested object
const figureIndentation = (lines, indentation) => {
  const [line, nextLine, ...tail] = lines

  if (line === undefined) {
    return []
  }

  if (nextLine === undefined) {
    return [{
      line: line.line,
      getChildren: () => [],
      getBlock: () => [],
    }]
  }

  assert(line.indentation === indentation, 'death')
  assert(nextLine.indentation >= indentation, 'more death')

  if (nextLine.indentation === indentation) {
    return [{
      getChildren: () => [],
      getBlock: () => [],
      line: line.line,
    }].concat(figureIndentation([nextLine, ...tail], indentation))
  }

  const higherOrEqualIndentation =
    line => line.indentation >= nextLine.indentation

  const children = _.takeWhile([nextLine, ...tail], higherOrEqualIndentation)
  const newLines = _.dropWhile(tail, higherOrEqualIndentation)

  return [{
    line: line.line,
    getChildren: () => figureIndentation(children, nextLine.indentation),
    getBlock: () =>
      children
      .map(child => (' ').repeat(child.indentation - nextLine.indentation) + child.line)
  }].concat(figureIndentation(newLines, indentation))
}

export default figureIndentation
