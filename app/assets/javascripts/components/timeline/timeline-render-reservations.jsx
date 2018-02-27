window.TimelineRenderReservations = {

  reservationLabel(timeline_availability, rr, color) {

    var label = TimelineUtil.username(timeline_availability, rr)

    var elements = [
      <span key='label'>{label}</span>
    ]

    var inventoryCode = TimelineUtil.inventoryCode(timeline_availability, rr)
    if(inventoryCode) {
      elements.push(
        <span key='inventory_code' style={{color: color, backgroundColor: '#383838', marginLeft: '10px', padding: '0px 3px 0px 3px'}}>{inventoryCode}</span>
      )
    }

    return elements
  },

  renderReservations(layouted, firstMoment, lastMoment, timeline_availability, invalidReservations, _onToggle) {

    return layouted.map((line, index) => {

      return line.map((rr) => {

        var start = moment(rr.start_date)
        var end = moment(rr.end_date)

        var offset = TimelineUtil.daysDifference(start, firstMoment)

        var height = 15
        var padding = 5
        var totalHeight = height + padding


        if(TimelineUtil.late(rr)) {
          var length = TimelineUtil.numberOfDays(start, end)
          var lateLength = TimelineUtil.numberOfDays(start, lastMoment) - length + 1
          var fullLength = TimelineUtil.numberOfDays(start, lastMoment)

          var labelOffset = offset
          if(labelOffset < 0) {
            labelOffset = 0
            fullLength = fullLength + offset
          }

          return [
            <div key={'reservation_late_' + rr.id} style={{position: 'absolute', top: (index * totalHeight) + 'px', left: (offset * 30 + length * 30) + 'px', width: (lateLength * 30) + 'px', height: height + 'px', border: '0px'}}>
              <div style={{backgroundColor: 'rgba(212, 84, 84, 0.5)', position: 'absolute', top: '0px', left: '0px', bottom: '0px', right: '0px', borderRadius: '0px 5px 5px 0px', margin: '0px 3px 0px 0px'}}>
                {' '}
              </div>
            </div>
            ,
            <div key={'reservation_' + rr.id} style={{position: 'absolute', top: (index * totalHeight) + 'px', left: (offset * 30) + 'px', width: (length * 30) + 'px', height: height + 'px', border: '0px'}}>
              <div style={{backgroundColor: 'rgba(212, 84, 84, 1.0)', position: 'absolute', top: '0px', left: '0px', bottom: '0px', width: (length * 30 - 4) + 'px', borderRadius: '5px 0px 0px 5px', margin: '0px 0px 0px 3px'}}>
                {' '}
              </div>
            </div>
            ,
            <div key={'reservation_label_' + rr.id} style={{position: 'absolute', top: (index * totalHeight) + 'px', left: (labelOffset * 30) + 'px', width: (fullLength * 30) + 'px', height: height + 'px', border: '0px'}}>
              <div onClick={(e) => _onToggle(e, rr)} style={{backgroundColor: 'none', color: '#eee', display: 'block', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', width: (fullLength * 30 - 4) + 'px', position: 'absolute', top: '0px', left: '0px', bottom: '0px', borderRadius: '5px 0px 0px 5px', padding: '2px 5px', margin: '0px 0px 0px 3px'}}>
                {TimelineRenderReservations.reservationLabel(timeline_availability, rr, '#eee')}
              </div>
            </div>

          ]

        } else {

          var length = TimelineUtil.numberOfDays(start, end)

          var backgroundColor = '#e3be1f'
          var margin = '0px 3px'
          var border = 'none'
          var padding = '2px 5px'
          if(invalidReservations[rr.id]) {
            margin = '0px 3px'
            border = '2px solid red'
            padding = '0px 5px'
          }

          var labelOffset = offset
          var labelLength = length
          if(labelOffset < 0) {
            labelOffset = 0
            labelLength = labelLength + offset
          }


          var invalidBorder = null
          if(invalidReservations[rr.id]) {

            invalidBorder = (
              <div key={'reservation_border_' + rr.id} style={{position: 'absolute', top: (index * totalHeight) + 'px', left: (offset * 30) + 'px', width: (length * 30) + 'px', height: height + 'px', border: '0px'}}>
                <div style={{backgroundColor: 'none', position: 'absolute', top: '0px', left: '0px', bottom: '0px', right: '0px', borderRadius: '5px', margin: '0px 3px 0px 3px', border: '2px solid red'}}>
                  {' '}
                </div>
              </div>

            )
          }

          return _.compact([
            <div key={'reservation_' + rr.id} style={{position: 'absolute', top: (index * totalHeight) + 'px', left: (offset * 30) + 'px', width: (length * 30) + 'px', height: height + 'px', border: '0px'}}>
              <div style={{backgroundColor: backgroundColor, position: 'absolute', top: '0px', left: '0px', bottom: '0px', right: '0px', borderRadius: '5px', margin: '0px 3px 0px 3px'}}>
                {' '}
              </div>
            </div>
            ,
            invalidBorder
            ,
            <div key={'reservation_label' + rr.id} style={{position: 'absolute', top: (index * totalHeight) + 'px', left: (labelOffset * 30) + 'px', width: (labelLength * 30) + 'px', height: height + 'px', border: '0px'}}>
              <div onClick={(e) => _onToggle(e, rr)} style={{backgroundColor: 'none', display: 'block', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', width: (labelLength * 30 - 4 - 3) + 'px', padding: '2px 5px', margin: '0px 3px'}}>
                {TimelineRenderReservations.reservationLabel(timeline_availability, rr, '#e3be1f')}
              </div>
            </div>
          ])
        }

      })

    })
  }

}
