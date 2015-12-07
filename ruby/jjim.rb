require 'pp'
require 'json'

require_relative 'classes'
require_relative 'makeGraph'

def graph(code)
  lines = code
    .split("\n")
    .select{ |x| x.strip != '' } # No empty lines
    .map{ |line| Indentation.new(line) }

  Grapher.make_graph(Line.new('', lines).get_children)
end
