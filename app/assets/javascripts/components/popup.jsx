(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React

  window.Popup = window.createReactClass({
    getDefaultProps: function () {
    return {
      trigger: 'hover'
    }
  },

    propTypes: {
      trigger: PropTypes.oneOf(['hover', 'click'])
    },

    getInitialState () {
      return {
        visible: false,
        insideThis: false,
        insideChild: false
      }
    },

    popupMouseLeave(event) {
      event.preventDefault()
      this.setState({
        insideThis: false,
      }, this.handleUpdates)
    },

    popupMouseOver(event) {
      event.preventDefault()
      this.setState({
        insideThis: true,
        rectangle: this.popupRef.getBoundingClientRect()
      }, this.handleUpdates)
    },

    contentMouseLeave(event) {
      event.preventDefault()
      this.setState({
        insideChild: false,
      }, this.handleUpdates)
    },

    contentMouseOver(event) {
      event.preventDefault()
      this.setState({
        insideChild: true
      }, this.handleUpdates)
    },

    handleUpdates(event) {
      if (this.props.trigger === 'hover') {
        this.setState({visible: this.state.insideChild || this.state.insideThis})
      }
    },

    handleClick(event) {
      if (this.props.trigger === 'click') {
        this.setState(state => ({...state, visible: !this.state.visible}))
      }
    },

    handleClickOutside: function(event) {
      if (!(this.state.insideChild || this.state.insideThis)) {
        this.setState({ visible: false });
      }
    },

    handleEscKey: function(event) {
      if (event.key === 'Escape') {
        this.setState({ visible: false });
      }
    },

    activateClickOutsideAndEsc: function () {
      document.addEventListener('mousedown', this.handleClickOutside);
      document.addEventListener('keydown', this.handleEscKey);
    },

    inactivateClickOutsideAndEsc: function () {
      document.removeEventListener('mousedown', this.handleClickOutside);
      document.removeEventListener('keydown', this.handleEscKey);
    },

    popupRef: null,

    componentWillReceiveProps(nextProps) {
      this.setState({rectangle: nextProps.popupRef.getBoundingClientRect()})
      if(nextProps.popupRef != this.popupRef) {

        if (this.popupRef) {
          this.popupRef.removeEventListener('mouseenter', this.popupMouseOver);
          this.popupRef.removeEventListener('mouseleave', this.popupMouseLeave);
          this.popupRef.removeEventListener('click', this.handleClick);
        }
        this.inactivateClickOutsideAndEsc()

        this.popupRef = nextProps.popupRef

        if (this.popupRef) {
          this.popupRef.addEventListener('mouseenter', this.popupMouseOver);
          this.popupRef.addEventListener('mouseleave', this.popupMouseLeave);
          this.popupRef.addEventListener('click', this.handleClick);
        }
      }
    },

    componentWillUpdate(nextProps, nextState) {
      if (this.props.trigger === 'click') {
        if (!this.state.visible && nextState.visible) {
          this.activateClickOutsideAndEsc()
        } else if (this.state.visible && !nextState.visible) {
          this.inactivateClickOutsideAndEsc()
        }
      }
    },

    componentWillUnmount() {
      if(this.popupRef) {
        this.popupRef.removeEventListener('mouseenter', this.popupMouseOver);
        this.popupRef.removeEventListener('mouseleave', this.popupMouseLeave);
        this.popupRef.removeEventListener('click', this.handleClick);
      }
      this.inactivateClickOutsideAndEsc()
    },

    renderPopup() {
      if(!this.state.visible) {
        return null
      }


      var style = {
        position: 'relative',
        left: '-50%',
        height: '100%'
      }

      return (
        <div style={style} onMouseEnter={this.contentMouseOver} onMouseLeave={this.contentMouseLeave}>
          {this.props.children}
        </div>
      )
    },

    render () {

      if(!this.state.visible) {
        return null
      }

      var r = this.state.rectangle
      var left = r.left + r.width * 0.5
      var top = r.top

      var outer = {
        position: 'fixed',
        top: top + 'px',
        left: left + 'px',
        zIndex: '1000000'
      }


      var inner = {
        position: 'absolute',
        bottom: '-10px'
      }

      return (
        <div style={outer}>
          <div style={inner}>
            {this.renderPopup()}
          </div>
        </div>
      )

    }
  })
})()
