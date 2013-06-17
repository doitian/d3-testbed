d3 = require 'd3'

dimen =
  margin: 20

drawKochCurve = (selection) ->
  width = selection.datum().width
  return if width < 3

  data = [
    { x: 0 }
    { x: width / 3, width: width / 4 }
    { x: width / 2, width: width / 4 }
    { x: width * 2 / 3 }
  ]
  for i, datum of data
    datum.id = i
    datum.y ||= 0
    datum.width ||= width / 3
    datum.rotate ||= 0

  selection.selectAll('line').classed('obsoleted', true)

  selection.selectAll('g').data(data, (d) -> d.id).
    enter().
    append('g').
    attr("transform", (d) -> "translate(#{d.x},#{d.y}) rotate(#{d.rotate})").
    append('line').
    classed('koch-curve', true).
    attr('x2', (d) -> d.width)

  selection.select('line.obsoleted').remove()

  data[1].width = data[2].width = width / 3
  data[1].rotate = - 60
  data[2].y = - width / Math.sqrt(12)
  data[2].rotate = 60

  selection.selectAll('g').data(data, (d) -> d.id).
    transition().
    each('end', -> d3.select(this).call(drawKochCurve)).
    attr("transform", (d) -> "translate(#{d.x},#{d.y}) rotate(#{d.rotate})").
    select('line').
    attr('x2', (d) -> d.width)

drawKochSnowflake = (size) ->
  canvas = d3.select('#canvas')
  canvas.html('')

  width = height = size + dimen.margin * 2
  svg = canvas.append('svg').attr
    width: width
    height: height
    viewBox: "0 0 300 300"

  r = 150
  height = r + r * Math.cos(Math.PI / 3)
  halfEdge = r * Math.sin(Math.PI / 3)

  # Transform to the start point of each line, and rotate the curve so it
  # grows upwards.
  g1 = svg.append('g')
  g1.attr('transform', "translate(#{r},0) rotate(60)")
  g2 = svg.append('g')
  g2.attr('transform', "translate(#{r+halfEdge},#{height}) rotate(180)")
  g3 = svg.append('g')
  g3.attr('transform', "translate(#{r-halfEdge},#{height}) rotate(300)")

  g1.datum(width: halfEdge * 2).call(drawKochCurve)
  g2.datum(width: halfEdge * 2).call(drawKochCurve)
  g3.datum(width: halfEdge * 2).call(drawKochCurve)

module.exports = ->
  d3.select('button').on 'click', ->
    size = d3.select('#size').property('value')

    if isNaN(parseInt(size, 10))
      alert("Invalid size: #{size}")

    drawKochSnowflake(parseInt(size, 10))
    d3.event.preventDefault()
