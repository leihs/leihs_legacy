(() => {
  const React = window.React

  window.TimelinePopup = window.createReactClass({
    propTypes: {
    },

    displayName: 'TimelinePopup',

    _handleClickOutside(event) {
      if (this.popup && !this.popup.contains(event.target)) {
        this.props._onClose()
      }
    },

    componentDidMount() {
      document.addEventListener('mousedown', this._handleClickOutside);
    },

    componentWillUnmount() {
      document.removeEventListener('mousedown', this._handleClickOutside);
    },

    render() {

      var x = this.props.x
      var y = this.props.y
      var rr = this.props.rr
      var timeline_availability = this.props.timeline_availability

      return (
        <div ref={(ref) => this.popup = ref} style={{zIndex: '1000', position: 'absolute', top: (y + 'px'), left: (x + 'px'), width: '260px', border: '1px solid black', borderRadius: '5px', margin: '0px', backgroundColor: '#fff', padding: '10px'}}>
          <div style={{fontSize: '16px', position: 'static', widthj: '260px'}}>
            <div className='timeline-event-bubble-title'>{TimelineRenderPopup.renderPopupLabel(timeline_availability, rr)}</div>
            <div className='timeline-event-bubble-body'>
              {TimelineRenderPopup.renderPopupPhone(timeline_availability, rr)}
              <br />
              {TimelineRenderPopup.renderPopupReservationDates(rr)}
              <br />
              {TimelineRenderPopup.renderPopupLateInfo(rr)}
              <br />
              <div className='buttons' style={{margin: '1.5em99'}}>
                {TimelineRenderPopup.renderPopupLink(timeline_availability, rr)}
              </div>
            </div>
          </div>
        </div>
      )
    }

  })
})()
