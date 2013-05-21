class Bracket
  constructor: (@options) ->
    @margin = @options.margin || { top: 30, right: 10, bottom: 10, left: 10 }
    @width = window.innerWidth - @margin.left - @margin.right
    @halfWidth = @width / 2
    @height = 500 - @margin.top - @margin.bottom
    @i = 0
    @duration = 500
    @data = @options.data

    @tree = d3.layout.tree().size [@height, @width]

    @vis = d3.select('#bracket').append('svg')
             .attr('width', @width + @margin.right + @margin.left)
             .attr('height', @height + @margin.top + @margin.bottom)
             .append('g')
             .attr('transform', "translate(#{@margin.left},#{@margin.top})")
    this.draw()

  _elbow: (d, i) =>
    source = @_calcLeft(d.source)
    target = @_calcLeft(d.target)
    hy = (target.y - source.y) / 2
    hw = -hy if d.isRight
    "M#{source.y},#{source.x}H#{(source.y + hy)}V#{target.x}H#{target.y}"

  _calcLeft: (d) =>
    l = d.y
    unless d.isRight
      l = d.y - @halfWidth
      l = @halfWidth - l
    x: d.x, y: l

  _getChildren: (d) ->
    a = []
    if d.west
      for game, i in d.west
        d.west[i].isRight = false
        d.west[i].parent = d
        a.push d.west[i]
    if d.east
      for game, i in (d.east || [])
        d.east[i].isRight = true
        d.east[i].parent = d
        a.push d.east[i]
    a

  _rebuildChildren: (node) =>
    node.children = @_getChildren(node)
    if node.children
      node.children.forEach(@_rebuildChildren)

  _toArray: (item, arr) ->
    arr = arr || []
    arr.push(item)
    @_toArray(c, arr) for c in (item.children || [])
    arr

  _update: (source) =>
    # Compute the new tree layout.
    nodes = @_toArray(source)

    # Normalize for fixed-depth.
    nodes.forEach (d) => d.y = d.depth * 140 + @halfWidth

    # Update the nodes…
    node = @vis.selectAll('g.node')
      .data nodes, (d) => d.id || (d.id = ++@i)

    # Enter any new nodes at the parent's previous position.
    nodeEnter = node.enter().append('g')
      .attr('class', 'node')
      .classed('edge', (d) -> d.children.length == 0)
      .classed('east', (d) -> d.isRight)
      .classed('west', (d) -> !d.isRight)
      .attr('transform', (d) -> "translate(#{source.y0},#{source.x0})")

    nodeEnter.append('circle')
      .attr('r', 1e-6)

    nodeEnter.append('text')
      .text((d) ->
        if d.rank?
          if d.isRight then "#{d.name} (#{d.rank})" else "(#{d.rank}) #{d.name}"
        else
          d.name
      )
      .style('fill-opacity', 1e-6)

    # Transition nodes to their new position.
    nodeUpdate = node.transition()
      .duration(@duration)
      .attr('transform', (d) =>
        p = @_calcLeft(d)
        "translate(#{p.y},#{p.x})"
      )

    nodeUpdate.select('circle')
      .attr('r', 4.5)
      .style('fill', (d) -> if d.games? then 'lightsteelblue' else '#fff')
      .style('opacity', (d) -> if d.children.length == 0 then 1e-6 else 1)

    nodeUpdate.select('text')
      .style('fill-opacity', 1)
      .attr('dy', (d) ->
        if d.children.length == 0 then -5 else -15
      )
      .attr('text-anchor', (d) ->
        if d.children.length == 0
          if d.isRight then 'end' else 'start'
        else
          'middle'
      )

    # Update the links...
    link = @vis.selectAll('path.link')
               .data(@tree.links(nodes), (d) -> d.target.id)

    # Enter any new links at the parent's previous position.
    link.enter().insert('path', 'g')
      .attr('class', 'link')
      .attr('d', (d) =>
        o = { x: source.x0, y: source.y0 }
        @_elbow({source: o, target: o})
      )

    # Transition links to their new position.
    link.transition()
      .duration(@duration)
      .attr('d', @_elbow)

    # Transition exiting nodes to the parent's new position.
    link.exit().transition()
      .duration(@duration)
      .attr('d', (d) =>
        o = @_calcLeft(d.source || source)
        if d.source.isRight
          o.y -= @halfWidth - (d.target.y - d.source.y)
        else
          o.y += @halfWidth - (d.target.y - d.source.y)
          @_elbow({source: o, target: o})
      )
      .remove()

  draw: () ->
    d3.json @data, (json) =>
      root = json
      root.x0 = @height / 2
      root.y0 = @width / 2

      t1 = d3.layout.tree().size([@height, @halfWidth]).children (d) -> d.west
      t2 = d3.layout.tree().size([@height, @halfWidth]).children (d) -> d.east
      t1.nodes(root)
      t2.nodes(root)

      @_rebuildChildren(root)
      root.isRight = false
      @_update(root)

window.Bracket = Bracket