# http://www.jasondavies.com/wordcloud/#http%3A%2F%2Fsearch.twitter.com%2Fsearch.json%3Frpp%3D100%26q%3D%7Bword%7D=cloud
# Compute the distinct nodes from the links.
width = 1260
height = 600
radius = 6
linkLookup = {}

# are these two nodes linked?
nodesLinked = (d, g) ->
  d.index == g.index || linkLookup["#{d.index},#{g.index}"] == 1 || linkLookup["#{g.index},#{d.index}"] == 1

tick = () ->
  # keep nodes constrained to their box
  node.attr('cx', (d) -> d.x = Math.max(radius, Math.min(width - radius, d.x)))
      .attr('cy', (d) -> d.y = Math.max(radius, Math.min(height - radius, d.y)))
      .attr 'transform', (d) -> "translate(#{d.x},#{d.y})"

  link.attr('x1', (d) -> d.source.x)
      .attr('y1', (d) -> d.source.y)
      .attr('x2', (d) -> d.target.x)
      .attr('y2', (d) -> d.target.y)

# Returns an event handler for fading a given node group.
fade = (opacity) ->
  (g, i) ->
    link
      .filter((d) -> d.source.index != i && d.target.index != i )
      .transition()
      .style('opacity', opacity)

    node
      .filter((d) -> nodesLinked(g, d) == false)
      .transition()
      .style('stroke-opacity', opacity)
      .style('fill-opacity', opacity)

    legend.text(if opacity == 1 then '' else g.desc)

color = d3.scale.category20()

force = d3.layout.force()
          .charge(-400)
          .linkDistance(160)
          .size([width, height]);

svg = d3.select('body').append('svg:svg')
        .attr('width', width)
        .attr('height', height)

legend = svg.append('svg:text')
            .attr('class', 'legend')
            .attr('x', 5)
            .attr('y', 20)
            .attr('width', 100)

d3.json 'public/data/season1.json', (graph) ->
  force
    .nodes(graph.nodes)
    .links(graph.links)
    .on('tick', tick)
    .start()

  @link = svg.selectAll('.link')
            .data(graph.links)
            .enter().append('svg:line')
            .attr('class', 'link')
            # .style("stroke-width", (d) -> Math.sqrt(d.value) )

  @node = svg.selectAll('.node')
            .data(graph.nodes)
            .enter().append('svg:g') #.append('circle')
            .attr('class', 'node')
            .attr('r', radius - .75)
            .on('mouseover', fade(0))
            .on('mouseout', fade(1))
            .call(force.drag)

  @node.append('svg:circle').attr('r', (d) -> (3 + d.total_time) / 10)#.style('fill', (d) -> color(d.group) )

  # node.append('title').text((d) -> d.name )
  @node.append("svg:text").attr('x', 12).attr('dy', '.35em').text (d) -> d.name

  # store links in lookup table
  @link.each((d) -> linkLookup["#{d.source.index},#{d.target.index}"] = 1)