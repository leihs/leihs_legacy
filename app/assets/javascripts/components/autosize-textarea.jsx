(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM

  window.AutosizeTextarea = window.createReactClass({
    propTypes: {
    },

    createAutosize() {
      this.jel.autosize()
    },

    destroyAutosize() {
      this.jel.trigger('autosize.destroy')
    },

    componentDidMount() {
      this.jel = $(this.refs[this.props.refkey])
      this.jel.on('focus', this.createAutosize).on('blur', this.destroyAutosize)
    },

    componentWillUnmount() {
      this.jel.off('focus', this.createAutosize).off('blur', this.destroyAutosize)
    },

    render () {
      return (
        <textarea ref={this.props.refkey} {...this.props} />
      )
    }
  })
})()
