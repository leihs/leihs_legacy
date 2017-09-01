#= require jquery
#= require jquery-ui
#= require jquery-ujs
#= require jquery.remotipart
#= require bootstrap
#= require accounting.js/accounting.js
#= require jquery-tokeninput
#= require underscore
#
#= require procurement/bootstrap-multiselect
#
#= require ./request-edit
#
#= require_self

$(document).ready ->
  $('form').on('submit', ->
    $(this).find('.btn-success > i.fa.fa-check').removeClass('fa-check').addClass('fa-circle-o-notch spinner')
  ).on 'ajax:complete', ->
    $(this).find('.btn-success > i.fa.fa-circle-o-notch.spinner').removeClass('fa-circle-o-notch').removeClass('spinner').addClass('fa-check')


  $('body').on 'focus mouseover', '[data-toggle="tooltip"]', -> $(this).tooltip('toggle')

# helpers
@inViewport = (el) ->
  return false if (!el || 1 != el.nodeType)
  html = document.documentElement
  r = el.getBoundingClientRect()
  return ( !!r &&
    r.bottom >= 0 &&
    r.right >= 0 &&
    r.top <= html.clientHeight &&
    r.left <= html.clientWidth
  )
