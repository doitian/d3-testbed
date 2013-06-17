d3 = require 'd3'
debounce = require 'debounce'

goldenRatio = 0.5 * (1 + Math.sqrt(5))

dimen =
  width: 500
  height: 500

dimen.chartWidth = Math.floor(dimen.width / goldenRatio)
dimen.chartHeight = dimen.chartWidth

dimen.pieRadius = Math.floor(dimen.chartWidth / 2)
dimen.innerRadius = Math.floor(dimen.pieRadius / goldenRatio)
dimen.pieThickness = dimen.pieRadius - dimen.innerRadius
dimen.ticksThickness = Math.floor(dimen.pieThickness / goldenRatio)
dimen.ticksRadius = dimen.innerRadius + dimen.ticksThickness
dimen.labelsRadius = dimen.width - dimen.pieRadius
dimen.labelsMiddleRadius = (dimen.labelsRadius + dimen.pieRadius) / 2

dimen.labelsStartAngle = Math.acos(dimen.pieRadius / dimen.labelsRadius)
dimen.labelsEndAngle = 3 * Math.PI / 2 - dimen.labelsStartAngle

pieColors = ['#990000', '#383838', '#ff7f0e']

resize = ->
  height = d3.max([window.innerHeight - 120, 120])
  d3.select('#canvas').style 'height', height + 'px'

drawDraft = (svg) ->
  g = svg.insert('g', ':first-child').classed('draft', true)
  g.attr('transform', "translate(#{dimen.pieRadius},#{dimen.pieRadius})")

  g.append('rect').
    attr('x', - dimen.pieRadius).
    attr('y', - dimen.pieRadius).
    attr('width', dimen.pieRadius * 2).
    attr('height', dimen.pieRadius * 2)
  g.append('rect').
    attr('x', - dimen.pieRadius).
    attr('y', - dimen.pieRadius).
    attr('width', dimen.width).
    attr('height', dimen.height)

  g.append('circle').attr('r', dimen.pieRadius)
  g.append('circle').attr('r', dimen.innerRadius)
  g.append('circle').attr('r', dimen.ticksRadius)
  g.append('circle').attr('r', dimen.labelsRadius)
  g.append('circle').attr('r', dimen.labelsMiddleRadius)

  chordLength = dimen.labelsRadius * Math.sin(dimen.labelsStartAngle)
  g.append('line').
    attr('x1', 0).attr('y1', 0).
    attr('x2', - dimen.pieRadius).attr('y2', chordLength)
  g.append('line').
    attr('x1', 0).attr('y1', 0).
    attr('x2', chordLength).attr('y2', - dimen.pieRadius)
  g.selectAll('line').attr('stroke', 'red')

drawDraft.revert = (svg) ->
  svg.select('g.draft').remove()

drawDraft.revert.revert = drawDraft

drawTicks = (svg) ->
  g = svg.append('g').classed('pie-ticks', true)
  g.attr('transform', "translate(#{dimen.pieRadius},#{dimen.pieRadius})")

  values = (1 for i in [1..18])
  data = d3.layout.pie()(values)

  arc = d3.svg.arc().
    innerRadius(dimen.innerRadius).
    outerRadius(dimen.ticksRadius)

  g.selectAll('path').data(data).
    enter().
    append('path').
    attr('class', 'tick bordered arc').
    attr('d', arc)

drawTicks.revert = (svg) ->
  svg.select('g.pie-ticks').remove()

drawPie = (svg) ->
  color = (d, i) -> pieColors[i % pieColors.length]

  data = svg.datum()[0].sort (a, b) ->
    d3.descending(a.likes, b.likes)

  totalLikes = d3.sum(d.likes for d in data)
  d.totalLikes = totalLikes for d in data

  pie = d3.layout.pie().value((d) -> d.likes)
  top3 = pie(data)[0...3]

  arc = d3.svg.arc().
    innerRadius(dimen.innerRadius).
    outerRadius(dimen.pieRadius)

  svg.append('g').classed('pie', true).
    attr('transform', "translate(#{dimen.pieRadius},#{dimen.pieRadius})").
    selectAll('path').data(top3).
    enter().
    append('path').
    attr('class', 'bordered arc').
    attr('d', arc).
    attr('fill', color)

drawPie.revert = (svg) ->
  svg.select('g.pie').remove()

drawLabel = (selection) ->
  selection.classed('label', true)

  percentify = d3.format('.3p')
  genderLabel = (d) ->
    if d.data.gender == 'men' then 'Males' else 'Females'
  ageLabel = (d) ->
    s = d.data.target_start_age
    e = d.data.target_end_age
    if s? && e?
      "Age #{s}-#{e}"
    else if s?
      "Age #{s}+"
    else if e?
      "Age <#{e}"
    else
      'Age All'

  color = (d, i) -> pieColors[i % pieColors.length]

  selection.append('line').
    attr('x1', 0).attr('y1', -40).
    attr('x2', 0).attr('y2', 8).
    attr('stroke-width', 3).
    attr('stroke', color)

  selection.append('text').classed('major-label', true).
    attr('text-anchor', 'end').
    attr('x', -10).
    attr('y', -8).
    attr('font-size', 25).
    attr('font-weight', 'bold').
    text((d) -> percentify(d.data.likes / d.data.totalLikes))

  selection.append('text').classed('minor-label', true).
    attr('text-anchor', 'begin').
    attr('x', 10).
    attr('y', -20).
    attr('font-size', 18).
    text(genderLabel)

  selection.append('text').classed('minor-label', true).
    attr('text-anchor', 'begin').
    attr('x', 10).
    attr('y', 0).
    attr('font-size', 18).
    text(ageLabel)

drawLabels = (svg) ->
  console.log [dimen.labelsStartAngle, dimen.labelsEndAngle]
  data = svg.select('g.pie').selectAll('path').data()

  firstAngle = data[0].endAngle - data[0].startAngle
  angleOffset = firstAngle * (goldenRatio - 1) / goldenRatio
  domain = [
    data[0].startAngle + angleOffset,
    data[data.length - 1].endAngle
  ]

  angleScale = d3.scale.linear().
    domain(domain).
    range([dimen.labelsStartAngle, dimen.labelsEndAngle])

  arc = d3.svg.arc().
    innerRadius(dimen.pieRadius).
    outerRadius(dimen.labelsRadius)

  transform = (d) ->
    console.log d
    console.log
      startAngle: angleScale(d.startAngle)
      endAngle: angleScale(d.endAngle)
    translation = arc.centroid
      startAngle: angleScale(d.startAngle)
      endAngle: angleScale(d.endAngle)

    "translate(#{translation})"

  svg.append('g').classed('labels', true).
    attr('transform', "translate(#{dimen.pieRadius},#{dimen.pieRadius})").
    selectAll('text').data(data).enter().
    append("g").
    attr('transform', transform).
    call(drawLabel)

drawLabels.revert = (svg) ->
  svg.select('g.labels').remove()

STEPS = [
  drawDraft
  drawTicks
  drawPie
  drawLabels
  drawDraft.revert
]

stepOf = (i) ->
  forward: (svg) ->
    if i of STEPS
      STEPS[i](svg)
      stepOf(i + 1)
    else
      @

  backward: (svg) ->
    if i - 1 of STEPS
      STEPS[i - 1].revert(svg)
      stepOf(i - 1)
    else
      @

module.exports = ->
  resize()
  d3.select(window).on 'resize', debounce(resize, 200)

  svg = d3.select('#canvas').append('svg').
    attr('viewBox', "0 0 #{dimen.width + 20} #{dimen.height + 20}")

  svg.append('clipPath').
    attr('id', 'canvasClipPath').
    append('rect').
    attr('x', -10).
    attr('y', -10).
    attr('width', dimen.width + 30).
    attr('height', dimen.height + 30)

  svg = svg.append('g').attr('clip-path', 'url(#canvasClipPath)').
    attr('transform', "translate(10,10)")

  step = stepOf(0)
  d3.json 'data.json', (error, json) ->
    if error
      alert error
    else
      svg.datum(json)

      d3.select(window).on 'keyup', ->
        switch d3.event.keyCode
          when 37, 72 # Left, h
            step = step.backward(svg)
          when 39, 76 # Right, l
            step = step.forward(svg)
