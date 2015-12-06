require 'pp'
require 'json'

require_relative 'classes'
require_relative 'figureIndentation'
require_relative 'makeGraph'

def graph(code)
  lines = code
    .split("\n")
    .select{ |x| x.strip != '' } # No empty lines
    .map{ |line| Indentation.new(line) }

  grapher = Grapher # Grapher.new

  if lines.length == 0
  then grapher.makeGraph([], 0)
  else grapher.makeGraph(figureIndentation(lines, lines[0].indentation))
  end
end
