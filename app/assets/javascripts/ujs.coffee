humanizeDates = ->
  $('[data-humanize-date]').each ->
    $el = $(this)
    utcDate = $el.data('humanizeDate')
    return unless utcDate
    md = moment(new Date(utcDate))
    $el
      .text(md.fromNow() + ' (' + md.toISOString() + ')')
      .attr('title', utcDate)

# run on load:
$ ->
  do humanizeDates
