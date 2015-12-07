require 'pp'
require 'json'

require_relative 'classes'
require_relative 'makeGraph'


def lines(code)
  code
  .split("\n")
  .select{ |x| x.strip != '' } # No empty lines
  .map{ |line| Indentation.new(line) }
end

def graph(code)
  lines = lines(code)
  Grapher.make_graph(Line.new('', lines).get_children)
end
