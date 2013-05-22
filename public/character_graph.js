(function() {
  var color, fade, force, height, legend, linkLookup, nodesLinked, radius, svg, tick, width;

  width = 1260;

  height = 600;

  radius = 6;

  linkLookup = {};

  nodesLinked = function(d, g) {
    return d.index === g.index || linkLookup["" + d.index + "," + g.index] === 1 || linkLookup["" + g.index + "," + d.index] === 1;
  };

  tick = function() {
    node.attr('cx', function(d) {
      return d.x = Math.max(radius, Math.min(width - radius, d.x));
    }).attr('cy', function(d) {
      return d.y = Math.max(radius, Math.min(height - radius, d.y));
    }).attr('transform', function(d) {
      return "translate(" + d.x + "," + d.y + ")";
    });
    return link.attr('x1', function(d) {
      return d.source.x;
    }).attr('y1', function(d) {
      return d.source.y;
    }).attr('x2', function(d) {
      return d.target.x;
    }).attr('y2', function(d) {
      return d.target.y;
    });
  };

  fade = function(opacity) {
    return function(g, i) {
      link.filter(function(d) {
        return d.source.index !== i && d.target.index !== i;
      }).transition().style('opacity', opacity);
      node.filter(function(d) {
        return nodesLinked(g, d) === false;
      }).transition().style('stroke-opacity', opacity).style('fill-opacity', opacity);
      return legend.text(opacity === 1 ? '' : g.desc);
    };
  };

  color = d3.scale.category20();

  force = d3.layout.force().charge(-400).linkDistance(160).size([width, height]);

  svg = d3.select('body').append('svg:svg').attr('width', width).attr('height', height);

  legend = svg.append('svg:text').attr('class', 'legend').attr('x', 5).attr('y', 20).attr('width', 100);

  d3.json('public/data/season1.json', function(graph) {
    force.nodes(graph.nodes).links(graph.links).on('tick', tick).start();
    this.link = svg.selectAll('.link').data(graph.links).enter().append('svg:line').attr('class', 'link');
    this.node = svg.selectAll('.node').data(graph.nodes).enter().append('svg:g').attr('class', 'node').attr('r', radius - .75).on('mouseover', fade(0)).on('mouseout', fade(1)).call(force.drag);
    this.node.append('svg:circle').attr('r', function(d) {
      return (3 + d.total_time) / 10;
    });
    this.node.append("svg:text").attr('x', 12).attr('dy', '.35em').text(function(d) {
      return d.name;
    });
    return this.link.each(function(d) {
      return linkLookup["" + d.source.index + "," + d.target.index] = 1;
    });
  });

}).call(this);
