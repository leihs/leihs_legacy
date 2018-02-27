(() => {
  const React = window.React

  window.TimelineNew = window.createReactClass({
    propTypes: {
    },

    displayName: 'TimelineNew',

    getInitialState() {
      return {
        preprocessedData: TimelinePreprocessData.preprocessData(this.props.timeline_availability),
        showPopup: null,
        popupReservation: null,
        popupPosition: null
      }
    },

    componentDidMount() {
      document.addEventListener('scroll', this._onScroll)
    },

    componentWillUnmount() {
      document.removeEventListener('scroll', this._onScroll)
    },

    _onToggle(event, rr) {
      event.preventDefault()

      var rect = event.nativeEvent.target.getBoundingClientRect()

      var x = window.scrollX + rect.left + event.nativeEvent.offsetX
      var y = window.scrollY + rect.top + rect.height * 0.5

      if(this.state.showPopup) {
        this.setState({
          popupPosition: {
            x: x,
            y: y
          }
        })
      } else {
        this.setState({
          showPopup: rr.id,
          popupPosition: {
            x: x,
            y: y
          },
          popupReservation: rr
        })
      }
    },

    _onClose() {
      this.setState({showPopup: null})
    },

    renderPopup(timeline_availability, rr) {
      if(!this.state.showPopup) {
        return null
      }

      if(this.state.showPopup != rr.id) {
        return null
      }

      var x = this.state.popupPosition.x
      var y = this.state.popupPosition.y

      return (
        <TimelinePopup _onClose={this._onClose} x={x} y={y} rr={rr} timeline_availability={timeline_availability} />
      )
    },

    _onScroll(event) {
      var elements = document.getElementsByClassName('scrollWithPage')
      _.each(elements, (e) => {
        e.style.left = TimelineRender.labelPosition(this.state.preprocessedData.firstMoment) + 'px'
      })
    },

    numberOfEntitlementQuantities(entitlementQuantities) {
      return _.reduce(
        entitlementQuantities,
        (memo, quantity) => memo + 1,
        0
      )
    },

    calcReservationsHeight(layouted) {
      return layouted.length * 20
    },

    render () {
      var preprocessedData = this.state.preprocessedData

      var firstMoment = preprocessedData.firstMoment
      var lastMoment = preprocessedData.lastMoment
      var numberOfDaysToShow = preprocessedData.numberOfDays
      var dayWidth = 30
      var relevantItemsCount = preprocessedData.relevantItemsCount
      var totalCounts = preprocessedData.totalCounts
      var reservationCounts = preprocessedData.reservationCounts
      var unusedCounts = preprocessedData.unusedCounts
      var allLayoutedReservationFrames = preprocessedData.allLayoutedReservationFrames
      var userEntitlementGroupsForModel = preprocessedData.userEntitlementGroupsForModel
      var entitlementQuantities = preprocessedData.entitlementQuantities
      var reservationsInGroups = preprocessedData.reservationsInGroups
      var wholeWidth = dayWidth * numberOfDaysToShow

      var unusedColors = (index) => {
        var delta = unusedCounts[index]
        if(delta > 0) {
          return 'rgb(170, 221, 170)'
        } else if(delta == 0) {
          return '#e4db5f'
        } else {
          return 'rgb(221, 170, 170)'
        }
      }

      var topMonths = 0
      var topDays = topMonths + 40
      var topTotalQuantities = topDays + 50
      var topEntitlementQuantities = topTotalQuantities + 50
      var entitlementLineHeight = 60
      var entitlementsHeight = this.numberOfEntitlementQuantities(entitlementQuantities) * entitlementLineHeight
      var topTest = topEntitlementQuantities + entitlementsHeight
      var topTest2 = topTest + entitlementLineHeight
      var topAvailabilities = topTest2 + entitlementLineHeight
      var topReservations = topAvailabilities + 70
      var wholeHeight = topReservations + this.calcReservationsHeight(allLayoutedReservationFrames) + 200

      return (
        <div style={{position: 'absolute', top: '0px', left: '0px', height: wholeHeight + 'px', width: wholeWidth + 'px', bottom: '0px', overflow: 'hidden'}}>
          <div style={{position: 'fixed', zIndex: '1000000000', left: '0px', right: '0px', bottom: '0px', height: '40px', backgroundColor: 'white'}}>
            <a href={window.location.href.replace('/timeline', '/old_timeline')}>
              <div style={{borderRadius: '5px', color: '#eee', textAlign: 'center', fontSize: '12px', padding: '6px', backgroundColor: '#4e4e4e', width: '200px', margin: '5px auto 5px auto'}}>
                Old Version
              </div>
            </a>
          </div>
          <div style={{position: 'absolute', top: topMonths + 'px', left: '0px', width: wholeWidth + 'px', bottom: '0px'}}>
            {TimelineRender.renderMonths(firstMoment, lastMoment)}
          </div>
          <div style={{position: 'absolute', top: topDays + 'px', left: '0px', width: wholeWidth + 'px', bottom: '0px'}}>
            {TimelineRender.renderDays(firstMoment, numberOfDaysToShow)}
          </div>
          <div style={{position: 'absolute', top: topReservations + 'px', left: '0px', width: wholeWidth + 'px'}}>
            {TimelineRenderReservations.renderReservations(allLayoutedReservationFrames, firstMoment, lastMoment, this.props.timeline_availability, this.state.preprocessedData.invalidReservations, this._onToggle)}
          </div>
          {TimelineRender.renderLabelSmall(firstMoment, 'Total:', topTotalQuantities)}
          {TimelineRender.renderIndexedQuantitiesSmall(null, (i) => relevantItemsCount, firstMoment, lastMoment, unusedColors, topTotalQuantities, wholeWidth, undefined)}

          {TimelineRender.renderEntitlementQuantityLabels(entitlementLineHeight, this.props.timeline_availability, this.state.preprocessedData.changesForDays, reservationsInGroups, entitlementQuantities, topEntitlementQuantities, wholeWidth, firstMoment, lastMoment, relevantItemsCount)}
          {TimelineRender.renderEntitlementQuantities(entitlementLineHeight, this.props.timeline_availability, this.state.preprocessedData.changesForDays, reservationsInGroups, entitlementQuantities, topEntitlementQuantities + 20, wholeWidth, firstMoment, lastMoment, relevantItemsCount)}

          {TimelineRender.renderBoldLabel(null, topTest, wholeWidth, 'müssen aus fremden Gruppen genommen werden', undefined, firstMoment)}
          {TimelineRender.renderNotAssignable(entitlementLineHeight, this.props.timeline_availability, this.state.preprocessedData.changesForDays, reservationsInGroups, entitlementQuantities, topTest + 20, wholeWidth, firstMoment, lastMoment, relevantItemsCount, unusedCounts)}

          {TimelineRender.renderBoldLabel(null, topTest2, wholeWidth, 'Überbuchungen', undefined, firstMoment)}
          {TimelineRender.renderNotEnough(entitlementLineHeight, this.props.timeline_availability, this.state.preprocessedData.changesForDays, reservationsInGroups, entitlementQuantities, topTest2 + 20, wholeWidth, firstMoment, lastMoment, relevantItemsCount, unusedCounts)}

          {TimelineRender.renderLabelSmall(firstMoment, 'Verfügbar:', topAvailabilities)}
          {TimelineRender.renderIndexedQuantities((i) => unusedCounts[i], firstMoment, lastMoment, unusedColors, topAvailabilities, wholeWidth, null)}


          {this.renderPopup(this.props.timeline_availability, this.state.popupReservation)}
        </div>
      )
    }
  })
})()
