require 'rubygems'
require 'csv'
require 'ostruct'
require 'json'
require 'matrix'

trash_rows = ['Credits', 'Background Story', 'Dream Sequence', 'Subjective POV', nil]
data = CSV.read('got-1-all.csv')
headers = data.shift

## Cleanup the Data
# headings for nodes
headers.slice!(0..2)

# remove 'Total' Column
data.map { |r| r.delete_at(headers.index('Total')) }

# remove credits and other trash rows
data.delete_if { |r| trash_rows.include? r[0]  }

# build links
# "links": [ {"episode": 1, "source":52,"target":39,"value":1}, ..] source and target are indexes on "nodes"
links = []
episodes = []
headers.each_with_index do |h, ci|
  if h =~ /Episode/ # new episode
    number, name = h.split(' - ')
    @episode = { number: number.gsub(/\D/, '').to_i, name: name.gsub('"','') }
    episodes << @episode[:number]
  else # minute or half minute key
    # get index of row where column == 1.0
    shared = data.each_index.select { |ri| data[ri].slice(ci) == '1.0' }
    if shared.size > 1
      links += shared.combination(2).map { |p| { episode: @episode[:number], source: p[0], target: p[1], value: 1 } }
    end
  end
end

# build nodes. e.g. { name: 'Name', background: true, desc: 'Verbose description' }
nodes = data.map { |l| l.slice!(0..2) }.map { |l| { name: l[0], background: l[1] == '1.0', desc: l[2] } }
nodes.each_with_index do |n, i|
  # get all links for this node
  nlinks = links.select { |l| l[:source] == i || l[:target] == i }
  # get an array of occurances where the array index is the episode index
  n[:times] = episodes.map { |e| nlinks.select { |l| l[:episode] == e }.size }
  n[:total_time] = n[:times].inject(&:+)
end

json = { nodes: nodes, links: links }
# puts json.to_json
# puts JSON.pretty_generate json
File.open('_source/public/data/season1.json', 'w').puts json.to_json