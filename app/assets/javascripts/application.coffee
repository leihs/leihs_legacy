#####
#
# this manifest includes all javascript files that are used in both:
# the borrow section and the manage section of leihs
#
#= require_self
#
##### THIRD PARTY LIBRARIES
#
# npm packages, served by Sprockets from node_modules (see config/initializers/assets.rb,
# versions pinned in package.json). jquery and fullcalendar are vendored because their
# exact upstream versions are not published on npm (see vendor/assets/javascripts/*/VENDOR.md).
# NOTE: the order matters (jquery first), keep it.
#
#= require jquery/jquery-1.10.2
#= require jquery-ui-dist/jquery-ui
#= require jquery-ujs/src/rails
#= require jquery-inview/jquery.inview
#= require moment/moment
#= require moment-range/dist/moment-range
#= require fullcalendar/fullcalendar-1.6.7
#= require underscore/underscore-umd
#= require accounting/accounting
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
window.PropTypes = appPack.PropTypes
window.createReactClass = appPack.createReactClass

window.lodash = appPack.lodash
window.setUrlParams = appPack.setUrlParams

# React components that used *directly* from non-webpack code
# (meaning using `React.render` directly, not the `react_rails` helpers)
['HandoverAutocomplete', 'CalendarDialog'].forEach((name) ->
  m = appPack.requireComponent('./' + name)
  # support default or named exports (if same name)
  if typeof m == 'object' && typeof m.default == 'function'
    m = m.default
  if typeof m == 'object' && typeof m[name] == 'function'
    m = m[name]
  # attach as global var
  window[name] = m
)
