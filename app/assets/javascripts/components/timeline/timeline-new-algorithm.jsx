window.TimelineNewAlgorithm = {

  hasPendingBooking(booking) {
    return this.pendingBooking(booking) != null
  },

  pendingBooking(booking) {
    return _.find(booking, (b) => b.assignment == null)
  },

  assignedBookings(booking) {
    return _.filter(booking, (b) => b.assignment != null)
  },

  trySimpleAssign(current, leftovers) {

    _.each(
      current.entitlementGroupIds,
      (egid) => {
        if(current.assignment == null && leftovers[egid] != undefined && leftovers[egid] > 0) {
          current.assignment = egid
          leftovers[egid]--
        }
      }
    )
  },

  tryModify(current, assignedBooking, leftovers) {

    var currentAssignment = assignedBooking.assignment
    var candidates = _.difference(
      assignedBooking.entitlementGroupIds,
      [currentAssignment]
    )
    candidates = _.difference(
      candidates,
      current.entitlementGroupIds
    )

    var candidate = _.find(
      candidates,
      (egid) => {
        return leftovers[egid] != undefined && leftovers[egid] > 0
      }
    )

    if(candidate) {
      current.assignment = assignedBooking.assignment
      leftovers[assignedBooking.assignment]--

      leftovers[assignedBooking.assignment]++
      leftovers[candidate]--
      assignedBooking.assignment = candidate
    }
  },

  modifyAnAssignedBooking(current, assignedBookings, leftovers) {

    _.each(
      assignedBookings,
      (ab) => {
        if(current.assignment == null) {
          this.tryModify(current, ab, leftovers)
        }
      }
    )
  },

  assignBooking(current, assignedBookings, leftovers) {

    this.trySimpleAssign(current, leftovers)
    if(current.assignment == null) {
      this.modifyAnAssignedBooking(current, assignedBookings, leftovers)
    }
    if(current.assignment == null) {
      current.assignment = ''
    }

  },

  newAlgorithm(reservations, constraints) {

    var leftovers = _.clone(constraints)
    var booking = _.map(reservations, (entitlementGroupIds, reservationId) => {
      return {
        reservationId: reservationId,
        assignment: null,
        entitlementGroupIds: _.sortBy(entitlementGroupIds, (v) => v) // general group '' first
      }
    })

    while(this.hasPendingBooking(booking)) {
      var current = this.pendingBooking(booking)
      var assignedBookings = this.assignedBookings(booking)
      this.assignBooking(
        current,
        assignedBookings,
        leftovers
      )

    }

    return booking
  }
}
