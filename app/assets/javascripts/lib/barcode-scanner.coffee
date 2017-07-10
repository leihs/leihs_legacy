# BarcodeScanner
#
# purpose: use hardware barcode scanner without focusing an input field first
# - collects keyboard input that does not target an input field
# - detects "fast input followed by enter key", like from Barcode Scanner hardware
# - on detection, finds target input field and fills + submits it

class BarcodeScanner

  constructor: ->
    @actions = []
    @buffer = null
    @delay = 100
    @timer = null

  addChar: (char)=>
    @buffer ?= ""
    @buffer += char
    window.clearTimeout @timer
    @timer = window.setTimeout (=> @buffer = null), @delay

  addAction: (string, callback)=>
    string = "^#{string.replace(/\(.*?\)/ig, "(\\S*)")}$"
    regexp = new RegExp(string)
    @actions.push
      regexp: regexp
      callback: callback

  execute: =>
    # HACK: support react inputs, need ref to element not DOM node
    target = if window.reactBarcodeScannerTarget
      window.reactBarcodeScannerTarget
    else
      $("[data-barcode-scanner-target]:last")

    code = @buffer
    action = @getAction code
    if action?
      action.callback.apply target, @getArguments(code, action)
    else
      currentVal = target.val() || ''
      target.val(currentVal + code)
      @submit target
    @buffer = null

  getAction: (code)=>
    for action in @actions
      if action.regexp.test code
        return action

  getArguments: (code, action)=>
    matches = action.regexp.exec(code)
    return matches[1..matches.length]

  keyPress: (e = window.event)=>
    # bail out if focus is already an input field!
    targetType = e.target.nodeName
    return if targetType == 'INPUT' || targetType == 'TEXTAREA'

    charCode = if (typeof e.which == "number") then e.which else e.keyCode
    char = String.fromCharCode(charCode)
    if (charCode == 13) and @buffer?
      do e.preventDefault
      do @execute
    else
      @addChar char

  submit: (target)=>
    input = if _.isFunction(target.closest) # its jQuery
      target
    else # its React…
      $(ReactDOM.findDOMNode(target))

    if not input.closest("[data-prevent-barcode-scanner-submit]").length
      input.closest("form").submit()

window.BarcodeScanner = new BarcodeScanner()

$(window).keypress window.BarcodeScanner.keyPress
