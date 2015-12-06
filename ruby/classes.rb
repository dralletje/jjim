class Indentation
  def initialize(line)
    withoutIndent = line.gsub(/^ */, '')

    @indentation = line.length - withoutIndent.length
    @line = withoutIndent
  end

  def line
    @line
  end

  def indentation
    @indentation
  end
end

class Line
  attr_reader :childLines
  attr_reader :line

  def initialize(line, childLines = [])
    @line = line
    @childLines = childLines
  end

  def getChildren
    nextLine = @childLines.first
    if nextLine.nil?
      []
    else
      figureIndentation(@childLines, nextLine.indentation)
    end
  end

  def getBlock
    nextLine = @childLines.first
    if nextLine.nil?
      []
    else
      @childLines.map{
        |child| (' ' * (child.indentation - nextLine.indentation)) + child.line
      }
    end
  end

  def simple
    {
      line: @line,
      children: getChildren.map{ |x| x.simple },
    }
  end
end

class Node
  attr_reader :type
  attr_reader :payload

  @@types = [
    :HTMLElement,
    :Logic,
    :Text,
    :Variable,
    :Block,
  ]

  def initialize(type, payload)
    Grapher.assert(@@types.include?(type), "Unknown type '#{type}'")

    @type = type
    @payload = payload
  end

  def to_json(*opts)
    {type: @type, payload: @payload}.to_json(*opts)
  end
end
