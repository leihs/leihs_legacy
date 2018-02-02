// This file is the (new) main entry point for client-side JavaScript.
// It is automatically compiled by Webpack.

// vendor-type deps (from npm)
import React from 'react'
import ReactDOM from 'react-dom'
import createReactClass from 'create-react-class'
import lodash from 'lodash'

// `react-rails` setup
import { ReactRailsUJS, componentRequireContext } from '../react-rails.js'

//
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//

// compat: exports from this file are exposed as window.Packs.application.FOO,
//         so they can be used from old sprockets-compiled `application.coffee`
// vendor modules

// some global helpers that we still need in old-style react
export { React, ReactDOM, createReactClass, lodash }

// react components bundle, when used *directly* from non-webpack code:
export { ReactRailsUJS, componentRequireContext as requireComponent }
