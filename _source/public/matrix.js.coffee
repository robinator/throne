class Matrix
  constructor: (@options) ->
    @actualFile = @options.actualFile
    @guessesFile = @options.guessesFile
    @vis = d3.select('#matrix')
    this.draw()

  _process: =>
    for guess in @guesses
      guess.score = 0
      guess.pointsPossible = 30
      eliminated = []
      for pick, i in guess.picks
        actual = @actual[i]
        eliminated.push(actual[1]) unless actual[1] == '???'
        pick[2] = 0
        if pick[0] == actual[0]
          # right
          guess.score += 1
          pick[2] += 1
          if pick[1] == actual[2]
            # and1
            guess.score += 1
            pick[2] += 1
          else
            guess.pointsPossible -= 1
        else if actual[0] != '???' || pick[0] in eliminated
          # wrong
          pick[2] -= 1
          guess.pointsPossible -= 2
        # console.log("#{guess.name}(#{i}) - pick: #{pick}, actual: #{actual}, score: #{guess.score} / #{guess.pointsPossible}")

  draw: ->
    d3.json @actualFile, (json) =>
      @actual = json
      @maxScore = @actual.length * 2

      d3.json @guessesFile, (json) =>
        @guesses = json
        @_process()

        tr = d3.select('tbody')
               .selectAll('tr')
               .data(@guesses)
               .enter()
               .append('tr')
               .sort((a, b) -> if a.score < b.score then 1 else if a.score == b.score then 0 else -1)

        td = tr.selectAll('td')
               .data((d) ->
                 arr = d.picks
                 arr.unshift(d.pointsPossible)
                 arr.unshift(d.score)
                 arr.unshift(d.name)
                 arr
               )
               .enter()
               .append('td')
               .classed('wrong', (d) -> typeof d == 'object' && d[2] == -1)
               .classed('right', (d) -> typeof d == 'object' && d[2] == 1)
               .classed('and1', (d) -> typeof d == 'object' && d[2] == 2)
               .classed('name', (d) -> typeof d == 'string')
               .text((d) =>
                 if typeof d == 'string'
                   d
                 else if typeof d == 'number'
                   d
                 else
                   "#{d[0]} in #{d[1]}"
               )

window.Matrix = Matrix