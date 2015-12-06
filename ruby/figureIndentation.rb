require_relative('classes')

def assert(pred, msg)
  if not pred
    raise Error, msg
  end
end

# Create nested object
def figureIndentation(lines, indentation)
  line, *first_tail = lines
  nextLine, *tail = first_tail

  if line.nil?
    return []
  end

  if nextLine.nil?
    return [Line.new(line.line)]
  end

  assert(line.indentation == indentation, 'death')
  assert(nextLine.indentation >= indentation, 'more death')

  if nextLine.indentation == indentation
    return [Line.new(line.line)] + figureIndentation(first_tail, indentation)
  end

  higherOrEqualIndentation = lambda {
    |line| line.indentation >= nextLine.indentation
  }

  children = first_tail.take_while(&higherOrEqualIndentation)
  newLines = first_tail.drop_while(&higherOrEqualIndentation)

  [Line.new(line.line, children)]
  .concat(figureIndentation(newLines, indentation))
end
