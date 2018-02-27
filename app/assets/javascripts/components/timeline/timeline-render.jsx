window.TimelineRender = {

  renderLabelSmall(firstMoment, text, top) {

    var offset = TimelineUtil.offset(firstMoment)

    return (
      <div style={{fontSize: '10px', padding: '4px', margin: '2px', position: 'absolute', top: top + 'px', left: (offset * 30 - 1000 - 20) + 'px', textAlign: 'right', width: '1000px', height: '30px', border: '0px'}}>
        {text}
      </div>
    )
  },

  renderValue(prefix, index, offset, value, backgroundColor) {
    return (
      <div key={prefix + index} style={{position: 'absolute', top: '0px', left: ((offset + index) * 30) + 'px', width: '30px', height: '30px', border: '0px'}}>
        <div style={{backgroundColor: backgroundColor, textAlign: 'center', fontSize: '16px', position: 'absolute', top: '0px', left: '0px', right: '0px', bottom: '0px', padding: '4px', margin: '2px', borderRadius: '5px'}}>
          {value}
        </div>
      </div>
    )
  },

  renderValueSmall(prefix, index, offset, value, backgroundColor) {
    return (
      <div key={prefix + index} style={{position: 'absolute', top: '0px', left: ((offset + index) * 30) + 'px', width: '30px', height: '30px', border: '0px'}}>
        <div style={{textAlign: 'center', fontSize: '10px', position: 'absolute', top: '0px', left: '0px', right: '0px', bottom: '0px', padding: '4px', margin: '2px'}}>
          {value}
        </div>
      </div>
    )
  },

  renderIndexedQuantities(valueFunc, firstMoment, lastMoment, colorFunc, top, wholeWidth, key) {

    var offset = TimelineUtil.offset(firstMoment)

    var range = _.range(
      0,
      TimelineUtil.numberOfDays(moment(), lastMoment)
    )

    var values = _.map(
      range,
      (i) => {

        var value = valueFunc(i)

        var color = colorFunc(i)

        return TimelineRender.renderValue('handout_count_', i, offset, value, color)
      }
    )

    return (
      <div style={{position: 'absolute', top: top + 'px', left: '0px', width: wholeWidth + 'px'}}>
        {values}
      </div>
    )
  },

  renderIndexedQuantitiesSmall(title, valueFunc, firstMoment, lastMoment, colorFunc, top, wholeWidth, key) {

    var offset = TimelineUtil.offset(firstMoment)

    var range = _.range(
      0,
      TimelineUtil.numberOfDays(moment(), lastMoment)
    )

    var values = _.map(
      range,
      (i) => {
        var value = valueFunc(i)
        var color = colorFunc(i)
        return TimelineRender.renderValueSmall('handout_count_', i, offset, value, color)
      }
    )

    return (
      <div key={key} title={title} style={{position: 'absolute', top: top + 'px', left: '0px', width: wholeWidth + 'px'}}>
        {values}
      </div>
    )
  },

  renderMonth(firstMoment, monthFrom, monthTo, isLast) {

    var offset = (m) => {
      return TimelineUtil.daysDifference(m, firstMoment)
    }

    var offset = offset(monthFrom)
    var length = TimelineUtil.numberOfDays(monthFrom, monthTo)

    var border = '1px solid black'
    if(isLast) {
      border = 'none'
    }

    return (
      <div key={'month_' + monthFrom.format('YYYY-MM')} style={{position: 'absolute', top: '0px', left: (offset * 30) + 'px', width: (length * 30) + 'px', bottom: '0px', border: '0px'}}>
        <div style={{fontSize: '14px', paddingTop: '10px', textAlign: 'center', position :'absolute', top: '0px', left: '0px', bottom: '0px', right: '0px', border: border, borderWidth: '0px 1px 0px 0px'}}>
          {monthFrom.format('MMMM')}
        </div>
      </div>
    )
  },

  renderMonths(firstMoment, lastMoment) {

    var months = []
    var monthFrom = moment(firstMoment)
    while(monthFrom.isSameOrBefore(lastMoment, 'day')) {

      var monthTo = moment(monthFrom).endOf('month')
      if(monthTo.isAfter(lastMoment)) {
        monthTo = moment(lastMoment)
      }

      months.push({
        from: monthFrom,
        to: monthTo
      })

      monthFrom = moment(monthTo).add(1, 'month').startOf('month')
    }

    return months.map((month, index) => {
      return TimelineRender.renderMonth(firstMoment, month.from, month.to, index == months.length - 1)
    })
  },

  renderDays(firstMoment, numberOfDaysToShow) {

    return _.map(
      _.range(0, numberOfDaysToShow),
      (i) => {

        var m = moment(firstMoment).add(i, 'days')

        var backgroundColor = 'none'
        if(m.isSame(moment(), 'day')) {
          backgroundColor = '#dadada'
        }

        return (
          <div key={'day_' + i} style={{position: 'absolute', top: '0px', left: (i * 30) + 'px', width: '30px', bottom: '0px', border: '0px'}}>
            <div style={{backgroundColor: backgroundColor, position :'absolute', top: '0px', left: '0px', bottom: '0px', right: '0px', border: '1px dotted black', borderWidth: '1px 1px 0px 0px'}}>
              <div style={{border: '1px dotted black', borderWidth: '0px 0px 1px 0px', paddingTop: '5px', paddingBottom: '5px', textAlign: 'center'}}>{m.format('DD')}</div>
            </div>
          </div>
        )
      }
    )
  },

  labelPosition(firstMoment) {

    var offset = TimelineUtil.offset(firstMoment)
    var x = 0

    if(window.scrollX > offset * 30 - 20) {
      x = window.scrollX + 20
    } else {
      x = offset * 30
    }

    return x
  },

  renderBoldLabel(title, top, wholeWidth, label, key, firstMoment) {

    var offset = TimelineUtil.offset(firstMoment)
    return (
      <div key={key} title={title} className='scrollWithPage' style={{fontWeight: 'bold', fontSize: '10px', padding: '4px', margin: '2px', position: 'absolute', top: top + 'px', left: (TimelineRender.labelPosition(firstMoment)) + 'px', textAlign: 'lef', width: '400px', height: '30px', border: '0px'}}>
        {label}
      </div>
    )
  },

  entitlementGroupNameForId(timeline_availability, groupId) {
    var entitlementGroup = _.find(
      timeline_availability.entitlement_groups,
      (eg) => {
        return eg.id == groupId
      }
    )

    var name = ''
    if(entitlementGroup) {
      name = entitlementGroup.name
    }

    return name
  },

  renderEntitlementQuantityLabel(title, timeline_availability, groupId, top, wholeWidth, quantity, firstMoment) {

    if(quantity < 0) {
      quantity = 0
    }
    if(groupId == '') {
      label = quantity + ' verfügbar für Allgemein, davon zugewiesen'
    } else {
      var name = TimelineRender.entitlementGroupNameForId(timeline_availability, groupId)
      label = quantity + ' reserviert für Gruppe ' + name + ', davon zugewiesen'
    }

    return TimelineRender.renderBoldLabel(title, top, wholeWidth, label, 'label_' + groupId, firstMoment)
  },

  reservationColors(index) {
    return 'rgb(210, 210, 210)'
  },

  renderNotEnough(lineHeight, timeline_availability, changesForDays, reservationsInGroups, entitlementQuantities, top, wholeWidth, firstMoment, lastMoment, relevantItemsCount, unusedCounts) {

    var quantity = entitlementQuantities['']

    var mappingAssigned = (index) => {

      if(!changesForDays[index]) {
        return '0'
      }

      var algo = changesForDays[index].algorithm
      var count = _.size(_.filter(algo, (a) => a.assignment == ''))

      if(unusedCounts[index] < 0) {
        return (
          <span style={{color: 'red'}}>{- unusedCounts[index]}</span>
        )
      } else {
        return 0
      }
    }
    return TimelineRender.renderIndexedQuantitiesSmall(null, mappingAssigned, firstMoment, lastMoment, TimelineRender.reservationColors,  top, wholeWidth, undefined)
  },

  renderNotAssignable(lineHeight, timeline_availability, changesForDays, reservationsInGroups, entitlementQuantities, top, wholeWidth, firstMoment, lastMoment, relevantItemsCount, unusedCounts) {

    var quantity = entitlementQuantities['']
    if(quantity < 0) {
      quantity = 0
    }

    var mappingAssigned = (index) => {

      if(!changesForDays[index]) {
        return '0'
      }

      var algo = changesForDays[index].algorithm
      var count = _.size(_.filter(algo, (a) => a.assignment == ''))

      if(count > quantity) {

        if(unusedCounts[index] < 0) {
          return (
            <span style={{color: 'red'}}>{count - quantity + unusedCounts[index]}</span>
          )
        } else {
          return (
            <span style={{color: 'red'}}>{count - quantity}</span>
          )
        }
      } else {
        return 0
      }
    }

    return TimelineRender.renderIndexedQuantitiesSmall(null, mappingAssigned, firstMoment, lastMoment, TimelineRender.reservationColors,  top, wholeWidth, undefined)
  },

  renderEntitlementQuantity(timeline_availability, changesForDays, reservationsInGroups, quantity, groupId, topEntitlement, wholeWidth, firstMoment, lastMoment, relevantItemsCount) {

    var mappingAssigned = (index) => {

      if(!changesForDays[index]) {
        return '0'
      }

      var algo = changesForDays[index].algorithm
      var count = _.size(_.filter(algo, (a) => a.assignment == groupId))

      if(quantity < 0) {
        return '0'
      } else

      if(count > quantity) {
        return quantity
      } else {
        return count
      }
    }

    return TimelineRender.renderIndexedQuantitiesSmall('Entitlement ' + groupId, mappingAssigned, firstMoment, lastMoment, TimelineRender.reservationColors,  topEntitlement, wholeWidth, 'reserved_' + groupId)
  },

  renderEntitlementQuantities(lineHeight, timeline_availability, changesForDays, reservationsInGroups, entitlementQuantities, topEntitlements, wholeWidth, firstMoment, lastMoment, relevantItemsCount) {

    return _.map(entitlementQuantities, (quantity, groupId) => {
      return {
        groupId: groupId,
        quantity: quantity
      }
    }).map((v, index) => {
      return TimelineRender.renderEntitlementQuantity(timeline_availability, changesForDays, reservationsInGroups, v.quantity, v.groupId, topEntitlements + index * lineHeight, wholeWidth, firstMoment, lastMoment, relevantItemsCount)
    })
  },

  renderEntitlementQuantityLabels(lineHeight, timeline_availability, changesForDays, reservationsInGroups, entitlementQuantities, topEntitlements, wholeWidth, firstMoment, lastMoment, relevantItemsCount) {
    return _.map(entitlementQuantities, (quantity, groupId) => {
      return {
        groupId: groupId,
        quantity: quantity
      }
    }).map((v, index) => {
      return TimelineRender.renderEntitlementQuantityLabel('Entitlement Info ' + v.groupId, timeline_availability, v.groupId, topEntitlements + index * lineHeight, wholeWidth, v.quantity, firstMoment)
    })
  }
}
