window.XhrContext = () => {

  return {

    xhrRefs: {},


    removeXhr(xhrKey) {
      delete this.xhrRefs[xhrKey]

    },

    reuseXhr(xhrKey, ajaxRef) {
      this.xhrRefs[xhrKey] = ajaxRef
    },


    cancelXhrs() {

      for(var k in this.xhrRefs) {
        this.xhrRefs[k].abort()
      }
      this.xhrRefs = {}

    },

    rememberXhr(ajaxRef) {
      var xhrKey = '' + new Date().getTime()
      this.xhrRefs[xhrKey] = ajaxRef

      return xhrKey

    },

    isEmpty() {

      return _.isEmpty(this.xhrRefs)
    },


    callXhr(xhr) {



    }

  }
}
