window.TimelineRenderPopup = {

  renderPopupPhone(timeline_availability, rr) {
    var user = TimelineUtil.findUser(timeline_availability, rr.user_id)
    return _jed('Phone') + ': ' + (user.phone ? user.phone : '')
  },

  startDateString(rr) {
    return moment(rr.start_date).format('DD.MM.YYYY')
  },

  endDateString(rr) {
    return moment(rr.end_date).format('DD.MM.YYYY')
  },

  renderPopupReservationDates(rr) {
    return _jed('Reservation') + ': ' + TimelineRenderPopup.startDateString(rr) + ' ' + _jed('until') + ' ' + TimelineRenderPopup.endDateString(rr)
  },

  renderPopupLateInfo(rr) {

    if(!TimelineUtil.late(rr)) {
      return null
    }

    return (
      <b>{_jed('Item is overdue and therefore unavailable!')}</b>
    )
  },

  renderPopupTakeBackLink(rr) {
    return '/manage/' + rr.inventory_pool_id + '/users/' + rr.user_id + '/take_back'
  },

  renderPopupHandOverLink(rr) {
    return '/manage/' + rr.inventory_pool_id + '/users/' + rr.user_id + '/take_back'
  },

  renderPopupAcknowledgeLink(rr) {
    return '/manage/' + rr.inventory_pool_id + '/orders/' + rr.order_id + '/edit'
  },

  renderPopupLink(timeline_availability, rr) {

    if(!timeline_availability.is_lending_manager) {
      return null
    }

    if(rr.status == 'submitted') {
      return (
        <a target='_top' href={TimelineRenderPopup.renderPopupAcknowledgeLink(rr)}>{_jed('Acknowledge')}</a>
      )
    } else if(rr.status == 'approved') {
      return (
        <a target='_top' href={TimelineRenderPopup.renderPopupTakeBackLink(rr)}>{_jed('Hand Over')}</a>
      )
    } else if(rr.status == 'signed') {
      return (
        <a target='_top' href={TimelineRenderPopup.renderPopupHandOverLink(rr)}>{_jed('Take Back')}</a>
      )
    } else {
      return null
    }
  },

  renderPopupLabel(timeline_availability, rr) {

    var username = TimelineUtil.username(timeline_availability, rr)
    var inventoryCode = TimelineUtil.inventoryCode(timeline_availability, rr)

    return username + (inventoryCode ? ' (' + inventoryCode  + ')' : '')
  }
}
