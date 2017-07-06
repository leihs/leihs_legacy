humanizeDates = ->
  $('[data-humanize-date]').each ->
    $el = $(this)
    utcDate = $el.data('humanizeDate')
    return unless utcDate
    $el
      .text(moment(new Date(utcDate)).calendar())
      .attr('title', utcDate)

# run on load:
$ ->
  do humanizeDates
