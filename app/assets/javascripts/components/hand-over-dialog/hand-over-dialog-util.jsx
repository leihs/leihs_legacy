window.HandOverDialogUtil = {

  _validateStartDate(reservations) {

    var hasErrors = _.any(
      reservations,
      (l) => {
        return moment(l.start_date).endOf('day').diff(moment().startOf('day'), 'days') > 0
      }
    )

    if(hasErrors) {
      App.Flash({
        type: 'error',
        message: _jed('you cannot hand out reservations which are starting in the future')
      })
      return false
    } else {
      return true
    }
  },

  _validateEndDate(reservations) {

    var hasErrors = _.any(
      reservations,
      (l) => {
        return moment(l.end_date).endOf('day').diff(moment().startOf('day'), 'days') < 0
      }
    )

    if(hasErrors) {
      App.Flash({
        type: 'error',
        message: _jed('you cannot hand out reservations which are ending in the past')
      })
      return false
    } else {
      return true
    }
  },

  _validateAssignment(reservations) {

    var hasErrors = _.any(
      reservations,
      (l) => {
        return l.item_id == null && l.option_id == null
      }
    )

    if(hasErrors) {
      App.Flash({
        type: 'error',
        message: _jed('you cannot hand out reservations with unassigned inventory codes')
      })
      return false
    } else {
      return true
    }

  },

  validateDialog(reservations) {
    return (
      this._validateStartDate(reservations)
      && this._validateEndDate(reservations)
      && this._validateAssignment(reservations)
    )
  },

  loadHandOverDialogData(parameters, callback) {

    var user = parameters.user
    var reservations = parameters.reservations


    $.ajax({
      url: App.Order.url(),
      data: JSON.stringify({
        reservation_ids: _.map(reservations, (r) => r.id)
      }),
      method: 'POST',
      contentType: 'application/json',
      dataType: 'json'
    }).done((data) => {

      var orders = data.map((datum) => {
        return App.Order.find(datum.id)
      })

      var purpose = _.uniq(
        _.map(orders, (o) => o.purpose)
      ).join("; ")


      if(this.validateDialog(reservations)) {

        callback(reservations, purpose)

      } else {
        return false
      }
    })

  }

}
