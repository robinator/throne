# http://blog.thomsonreuters.com/index.php/mobile-patent-suits-graphic-of-the-day/

# Compute the distinct nodes from the links.

mouseover = -> d3.select(this).select('circle').transition().duration(750).attr 'r', 16
mouseout = -> d3.select(this).select('circle').transition().duration(750).attr 'r', 8


width = 1260
height = 600
radius = 6
color = d3.scale.category20()

force = d3.layout.force()
          .charge(-500)
          .linkDistance(60)
          .size([width, height]);

svg = d3.select('body').append('svg:svg')
        .attr('width', width)
        .attr('height', height)

d3.json '/public/data/mis.json', (graph) ->
  force
    .nodes(graph.nodes)
    .links(graph.links)
    .start()

  link = svg.selectAll('.link')
            .data(graph.links)
            .enter().append('svg:line')
            .attr('class', 'link')
            # .style("stroke-width", (d) -> Math.sqrt(d.value) )

  node = svg.selectAll('.node')
            .data(graph.nodes)
            .enter().append('svg:g') #.append('circle')
            .attr('class', 'node')
            .attr('r', radius - .75)
            .on('mouseover', mouseover)
            .on('mouseout', mouseout)
            .call(force.drag)

  node.append('svg:circle').attr('r', (d) -> Math.floor(Math.random() * 10)).style('fill', (d) -> color(d.group) )

  # node.append('title').text((d) -> d.name )
  node.append("svg:text").attr("x", 12).attr("dy", ".35em").text (d) -> d.name

  force.on 'tick', () ->
    # keep nodes constrained to their box
    node.attr('cx', (d) -> d.x = Math.max(radius, Math.min(width - radius, d.x)) )
        .attr('cy', (d) -> d.y = Math.max(radius, Math.min(height - radius, d.y)) )

    link.attr('x1', (d) -> d.source.x )
        .attr('y1', (d) -> d.source.y )
        .attr('x2', (d) -> d.target.x )
        .attr('y2', (d) -> d.target.y )
    node.attr 'transform', (d) -> "translate(#{d.x},#{d.y})"
