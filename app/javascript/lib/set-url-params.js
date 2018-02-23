const parseUrl = require('url').parse
const formatUrl = require('url').format
const { merge, reduce, set, isObject, isString } = require('lodash')
const qs = require('qs')
const parseQuery = qs.parse

const formatQuery = obj =>
  qs.stringify(obj, {
    skipNulls: true,
    arrayFormat: 'brackets' // NOTE: do it like rails
  })

// setUrlParams('/foo?foo=1&bar[baz]=2', {bar: {baz: 3}}, …)
// setUrlParams({path: '/foo', query: {foo: 1, bar: {baz: 2}}, {bar: {baz: 3}}, …)
// >>> '/foo?foo=1&bar[baz]=3'
const setUrlParams = (currentUrl = '', ...params) => {
  // accepts URL as string, or object in either DOM or nodejs flavor:
  const url = urlFromStringOrObject(currentUrl)
  return formatUrl(
    merge(url, {
      path: null,
      pathname: url.pathname || url.path,
      search: formatQuery(
        merge({}, parseQuery(url.query), reduce(params, (a, b) => merge({}, a, b)))
      )
    })
  )
}
export default setUrlParams

// helper
const urlFromStringOrObject = url => {
  // NOTE: `path` must only be used if no `pathname` is given!
  if (isObject(url) && (isString(url.path) || isString(url.pathname))) {
    return url // already parsed!
  }
  if (isString(url)) {
    const parsedUrl = parseUrl(url)
    return set(parsedUrl, 'query', parsedUrl.query)
  }
  throw new Error('Invalid URL!')
}
