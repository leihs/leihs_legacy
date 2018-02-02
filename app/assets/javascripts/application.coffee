#####
#
# this manifest includes all javascript files that are used in both:
# the borrow section and the manage section of leihs
#
#= require_self
#
##### RAILS ASSETS
#
#= require jquery
#= require jquery-ui
#= require jquery-ujs
#= require jquery.inview
#= require moment
#= require fullcalendar
#= require underscore
#= require accounting.js/accounting.js
#
##### VENDOR
#
#= require jed/jed
#= require jsrender
#= require underscore/underscore.string
#= require underscore/underscore.each_slice
#= require bootstrap/bootstrap-modal
#= require bootstrap/bootstrap-dropdown
#= require tooltipster/tooltipster
#= require uri.js/src/URI
#
##### SPINE
#
#= require spine/spine
#= require spine/manager
#= require spine/ajax
#= require spine/relation
#
##### APP
#
#= require_tree ./initializers
#= require_tree ./lib
#= require_tree ./modules
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#
##### REACT (old)
#
# FIXME: remove react + components from sprockets-bundle
#= XXX require react
#= XXX require react_ujs
#= require_tree ./components
#
#
##### UJS (must be last so setup is done!)
#= require ujs
#
#####

window.App ?= {}
window.Tools ?=
  inspect: (val) =>
    console.log(val)
    val

window.App.Modules ?= {}

# use exports from webpack packs as globals for existing code:
appPack = window.Packs.application
window.React = appPack.React
window.ReactDOM = appPack.ReactDOM
window.createReactClass = appPack.createReactClass

window.lodash = appPack.lodash

# React components that used *directly* from non-webpack code
# (meaning using `React.render` directly, not the `react_rails` helpers)
['HandoverAutocomplete'].forEach((name) ->
  m = appPack.requireComponent('./' + name)
  # support default or named exports (if same name)
  if typeof m == 'object' && typeof m.default == 'function'
    m = m.default
  if typeof m == 'object' && typeof m[name] == 'function'
    m = m[name]
  # attach as global var
  window[name] = m
)
