// This file is the (new) main entry point for client-side JavaScript.
// It is automatically compiled by Webpack.

// vendor-type deps (from npm)
import React from 'react'
import ReactDOM from 'react-dom'
import createReactClass from 'create-react-class'
import lodash from 'lodash'
import PropTypes from 'prop-types'
import setUrlParams from '../lib/set-url-params'

// jQuery and libraries previously provided by the rails-assets.org gems.
// jQuery must be set as a global *before* the jQuery plugins below are
// imported, since those plugins attach themselves to the global jQuery.
import jQuery from 'jquery'
window.$ = window.jQuery = jQuery

// jQuery plugins (attach to the global jQuery on import)
import 'jquery-ui-dist/jquery-ui.js'
import 'jquery-ujs'
import 'jquery-autosize'
import '../vendor/jquery.inview-1.1.2.js'
import '../vendor/fullcalendar-1.6.7.js'

// non-jQuery libraries still used as globals by the old sprockets code
import moment from 'moment'
import _ from 'underscore'
import accounting from 'accounting'
window.moment = moment
window._ = _
window.accounting = accounting

// `react-rails` setup
import { ReactRailsUJS, componentRequireContext } from '../react-rails.js'

//
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//

// compat: exports from this file are exposed as window.Packs.application.FOO,
//         so they can be used from old sprockets-compiled `application.coffee`
// vendor modules

// some global helpers that we still need in old-style react
export { React, ReactDOM, PropTypes, createReactClass, lodash, setUrlParams }

// react components bundle, when used *directly* from non-webpack code:
export { ReactRailsUJS, componentRequireContext as requireComponent }
