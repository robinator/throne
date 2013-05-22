require 'rubygems'
require 'csv'
require 'ostruct'
require 'json'

data = CSV.read('got-1-1.csv')
points = []
headers = data.shift
# episode_name = headers[0]
# episode_number = episode_name.gsub(/\D/, '')

# "nodes": [ {"name":"Point Name","times":22}, ..]
# "links": [ {"source":52,"target":39,"value":1}, ..] source and target are indexes on "nodes"
json = { nodes: [], links: [] }

# build data objects and create nodes
data[0..-1].each_with_index do |plot_point, index|
  pp = OpenStruct.new(name: plot_point[0])
  pp.id = index
  pp.times = plot_point[0..-2].each_index.select{ |i| plot_point[i] == '1' }.map { |i| i - 1 }
  pp.total_time = pp.times.size
  if pp.total_time > 0
    points << pp
    json[:nodes] << { id: pp.id, name: pp.name.slice(0..20), desc: pp.name, total_time: pp.total_time }
  end
end

minutes = points.map(&:times).flatten.uniq.max

# create links
0.upto(minutes) do |minute|
  # get all plot points that share this minute
  links = points.select { |p| p.times.include?(minute) }.map(&:id)
  if links.size > 1
    # TODO extract counts of cobinations as well?
    combos = links.combination(2).map { |p| { source: p[0], target: p[1], value: 1, minute: minute } }
    json[:links] += combos
  end
end

puts json.to_json
# puts JSON.pretty_generate json