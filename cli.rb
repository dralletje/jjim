require_relative 'ruby/jjim'

contents = STDIN.read

puts JSON.pretty_generate(graph(contents))
