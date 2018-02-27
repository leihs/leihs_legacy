window.TimelinePreprocessData = {

  firstReservationMoment() {
    return moment().add(- 7, 'days')
  },

  isAfter(m1, m2) {
    return m1.isAfter(m2, 'day')
  },

  findMaximumMoment(moments) {
    return _.reduce(
      moments,
      (memo, m) => {
        if(memo == null) {
          return m
        } else {
          if(TimelineUtil.isAfter(m, memo)) {
            return m
          } else {
            return memo
          }
        }
      },
      null
    )
  },

  mapToMoments(isoDates) {
    return isoDates.map(
      (iso) => moment(iso)
    )
  },

  reservationEndDates(timeline_availability) {
    return timeline_availability.running_reservations.map(
      (rr) => rr.end_date
    )
  },

  lastReservationMoment(timeline_availability) {

    if(timeline_availability.running_reservations.length == 0) {
      return moment().add(3, 'months')
    }

    var m = TimelinePreprocessData.findMaximumMoment(
      TimelinePreprocessData.mapToMoments(
        TimelinePreprocessData.reservationEndDates(timeline_availability)
      )
    )

    if(m.isSameOrBefore(moment(), 'day')) {
      return moment().add(+ 1, 'month')
    } else {
      var inOneYear = moment().add(1, 'year')
      if(m.endOf('month').isAfter(inOneYear)) {
        return inOneYear
      } else {
        return m.add(+ 1, 'month')
      }
    }
  },

  relevantItems(timeline_availability) {
    return _.filter(
      timeline_availability.items,
      (i) => {
        return i.is_borrowable && !i.is_broken && !i.retired
      }
    )
  },

  relevantItemsCount(timeline_availability) {
    return TimelinePreprocessData.relevantItems(timeline_availability).length
  },

  totalCounts(lastMoment, relevantItemsCount) {
    return _.range(
      0,
      TimelineUtil.numberOfDays(moment(), lastMoment)
    ).map((i) => {
      return relevantItemsCount
    })
  },

  reservationIntersectsDay(rf, day) {
    var start = moment(rf.start_date)
    var end = moment(rf.end_date)
    var late = TimelineUtil.late(rf)
    var reserved = TimelineUtil.reserved(rf)

    if(!reserved && TimelineUtil.isAfter(start, day) || !late && TimelineUtil.isAfter(day, end)) {
      return false
    } else {
      return true
    }
  },

  reservationsForDay(timeline_availability, day) {
    return _.filter(
      timeline_availability.running_reservations,
      (r) => TimelinePreprocessData.reservationIntersectsDay(r, day)
    )
  },

  handoutCounts(timeline_availability, lastMoment) {

    return _.range(
      0,
      TimelineUtil.numberOfDays(moment(), lastMoment)
    ).map((i) => {

      var day = moment().add(i, 'days')
      return _.filter(
        TimelinePreprocessData.reservationsForDay(timeline_availability, day),
        (r) => {
          return r.status == 'signed'
        }
      )

    })
  },

  reservationCounts(timeline_availability, lastMoment) {

    return _.range(
      0,
      TimelineUtil.numberOfDays(moment(), lastMoment)
    ).map((i) => {

      var day = moment().add(i, 'days')
      return _.filter(
        TimelinePreprocessData.reservationsForDay(timeline_availability, day),
        (r) => {
          return r.status != 'signed'
        }
      )
    })
  },

  sortedReservations(reservations) {

    return _.sortBy(
      reservations,
      (r) => {
        var compare = ''
        if(!r.end_date || TimelineUtil.late(r)) {
          compare += '9999-99-99'
        } else {
          compare += r.end_date
        }
        compare += '/'
        if(!r.start_date) {
          compare += '0000-00-00'
        } else {
          compare += r.start_date
        }
        return compare
      }
    )
  },

  hasIntersection(rfs, rf) {

    return _.find(rfs, (rfi) => {

      var startA = moment(rf.start_date)
      var endA = moment(rf.end_date)
      var lateA = TimelineUtil.late(rf)
      var reservedA = TimelineUtil.reserved(rf)
      var startB = moment(rfi.start_date)
      var endB = moment(rfi.end_date)
      var lateB = TimelineUtil.late(rfi)
      var reservedB = TimelineUtil.reserved(rfi)

      if(!lateB && !reservedA && TimelineUtil.isAfter(startA, endB) || !lateA && !reservedB && TimelineUtil.isAfter(startB, endA)) {
        return false
      } else {
        return true
      }
    })
  },

  findNoneIntersectionLine(lines, rf) {
    return _.find(lines, (line) => {
      return !TimelinePreprocessData.hasIntersection(line, rf)
    })
  },

  layoutReservationFrames(reservations) {

    var rfs = TimelinePreprocessData.sortedReservations(reservations)

    return _.reduce(
      rfs,
      (memo, rf) => {

        if(memo.length == 0) {
          return memo.concat([[rf]])
        } else {

          var line = TimelinePreprocessData.findNoneIntersectionLine(memo, rf)

          if(!line) {
            return memo.concat([[rf]])
          } else {
            line.push(rf)
            return memo
          }

        }
      },
      []
    ).map((line) => {
      return _.sortBy(line, (rfi) => {
        return rfi.start_date
      })
    })
  },

  calculateUserEntitlementGroups(timeline_availability) {

    return _.object(
      timeline_availability.reservation_users.map((u) => {
        return [
          u.id,

          _.compact( // compact should theoretically not be needed, but there are exceptions e.g.: http://localhost:3000/manage/8bd16d45-056d-5590-bc7f-12849f034351/models/6ef67281-54f1-5460-a5ba-ae984d01d43c/timeline
            _.filter(timeline_availability.entitlement_groups_users, (egu) => {
              return egu.user_id == u.id
            }).map(
              (egu) => {
                return _.find(timeline_availability.entitlement_groups, (eg) => {
                  return eg.id == egu.entitlement_group_id
                })
              }
            )
          )
        ]
      })
    )
  },

  userEntitlementGroupsForModel(timeline_availability) {

    var userEntitlementGroups = TimelinePreprocessData.calculateUserEntitlementGroups(timeline_availability)

    var entitlementGroupIds = timeline_availability.entitlements.map((e) => e.entitlement_group_id)

    return _.object(
      _.map(
        userEntitlementGroups,
        (uegs, uid) => {

          return [
            uid,
            _.filter(
              uegs,
              (ueg) => {
                return _.contains(entitlementGroupIds, ueg.id)
              }
            )
          ]
        }
      )
    )
  },

  entitlementQuantities(timeline_availability, relevantItemsCount) {

    return _.object(timeline_availability.entitlements.map((e) => {
      return [
        e.entitlement_group_id,
        e.quantity
      ]
    }).concat([
      [
        '',
        relevantItemsCount - _.reduce(
          timeline_availability.entitlements,
          (memo, e) => memo + e.quantity,
          0
        )
      ]
    ]))
  },

  groupsForUser(user_id, timeline_availability) {
    return _.filter(timeline_availability.entitlement_groups_users, (egu) => {
      return egu.user_id == user_id
    }).map((egu) => egu.entitlement_group_id)
  },

  groupsForUsers(timeline_availability) {
    return _.object(timeline_availability.reservation_users.map((u) => {
      return [
        u.id,
        TimelinePreprocessData.groupsForUser(u.id, timeline_availability)
      ]
    }))
  },

  isReservationInGroup(reservation, groupId, timeline_availability) {
    return _.contains(TimelinePreprocessData.groupsForUsers(timeline_availability)[reservation.user_id], groupId)
  },

  reservationsInGroups(timeline_availability, entitlementQuantities, lastMoment, relevantItemsCount) {

    return _.range(
      0,
      TimelineUtil.numberOfDays(moment(), lastMoment)
    ).map((i) => {

      var day = moment().add(i, 'days')

      var dayReservations = TimelinePreprocessData.reservationsForDay(timeline_availability, day)

      return _.mapObject(entitlementQuantities, (q, g) => {

        return _.filter(
          dayReservations,
          (r) => {
            return TimelinePreprocessData.isReservationInGroup(r, g, timeline_availability)
          }
        )

      })
    })
  },

  changesDates(timeline_availability) {

    return _.sortBy(
      _.map(
        _.reduce(
          timeline_availability.running_reservations,
          (memo, r) => {

            var ds = []
            memo[r.start_date] = r.start_date
            var before_start_date = moment(r.start_date).add(- 1, 'days').format('YYYY-MM-DD')
            memo[before_start_date] = before_start_date
            if(!TimelineUtil.late(r)) {
              memo[r.end_date] = r.end_date
              var after_end_date = moment(r.end_date).add(+ 1, 'days').format('YYYY-MM-DD')
              memo[after_end_date] = after_end_date

            }

            return memo
          },
          {}
        ),
        (v) => v
      ),
      (v) => v
    )
  },

  calculateChangesReservations(timeline_availability, change) {
    var m = moment(change)
    return _.filter(
      timeline_availability.running_reservations,
      (r) => {
        var start = moment(r.start_date)
        var end = moment(r.end_date)
        return start.isSameOrBefore(m) && (end.isSameOrAfter(m) || TimelineUtil.late(r))
      }
    )
  },

  reservationEntitlements(timeline_availability, reservation, userEntitlementGroupsForModel) {
    var userId = reservation.user_id
    var entitlements = userEntitlementGroupsForModel[userId]
    return entitlements.map((e) => e.id)
  },

  newAlgorithmForReservations(timeline_availability, reservationsList, userEntitlementGroupsForModel, relevantItemsCount) {

    var reservations = _.object(reservationsList.map((r) => {
      return [
        r.id,
        TimelinePreprocessData.reservationEntitlements(timeline_availability, r, userEntitlementGroupsForModel).concat([''])
      ]
    }))

    var constraints = _.object(
      timeline_availability.entitlements.map((e) => {
        return [
          e.entitlement_group_id,
          e.quantity
        ]
      }).concat([
        [
          '',
          relevantItemsCount - _.reduce(
            timeline_availability.entitlements,
            (memo, e) => memo + e.quantity,
            0
          )
        ]
      ])
    )

    return TimelineNewAlgorithm.newAlgorithm(reservations, constraints)
  },

  changesAlgorithm(timeline_availability, changes, userEntitlementGroupsForModel, relevantItemsCount) {
    return changes.map((c) => {
      var reservations = TimelinePreprocessData.calculateChangesReservations(timeline_availability, c)
      return {
        change: c,
        date: c,
        reservations: reservations,
        algorithm: TimelinePreprocessData.newAlgorithmForReservations(timeline_availability, reservations, userEntitlementGroupsForModel, relevantItemsCount),
        available: relevantItemsCount - _.size(reservations)
      }
    })
  },

  changesForDays(timeline_availability, lastMoment, changesAlgorithm, relevantItemsCount) {

    return _.range(
      0,
      TimelineUtil.numberOfDays(moment(), lastMoment)
    ).map((i) => {

      var day = moment().add(i, 'days')

      return _.last(_.filter(
        changesAlgorithm,
        (c) => {
          var cm = moment(c.date)

          return day.isSameOrAfter(cm, 'day')
        }
      ))
    })
  },

  invalidReservations(timeline_availability, changesAlgorithm, relevantItemsCount) {

    var invalids = _.filter(
      changesAlgorithm,
      (c) => relevantItemsCount - _.size(c.reservations) < 0
    ).map((c) => c.change)

    var rids = _.uniq(_.flatten(invalids.map((c) => {
      return _.filter(
        TimelinePreprocessData.calculateChangesReservations(timeline_availability, c),
        (r) => !r.item_id
      ).map(
        (r) => r.id
      )
    })))

    return _.object(rids.map((rid) => [rid, rid]))
  },

  preprocessData(timeline_availability) {
    var firstMoment = TimelinePreprocessData.firstReservationMoment()
    var lastMoment = TimelinePreprocessData.lastReservationMoment(timeline_availability)
    var numberOfDays = TimelineUtil.numberOfDays(firstMoment, lastMoment)
    var relevantItemsCount = TimelinePreprocessData.relevantItemsCount(timeline_availability)
    var totalCounts = TimelinePreprocessData.totalCounts(lastMoment, relevantItemsCount)
    var handoutCounts = TimelinePreprocessData.handoutCounts(timeline_availability, lastMoment).map((hc) => - hc.length)
    var borrowableCounts = _.zip(totalCounts, handoutCounts).map((p) => _.first(p) + _.last(p))
    var reservationCounts = TimelinePreprocessData.reservationCounts(timeline_availability, lastMoment).map((rc) => - rc.length)
    var unusedCounts = _.zip(borrowableCounts, reservationCounts).map((p) => _.first(p) + _.last(p))
    var allLayoutedReservationFrames = TimelinePreprocessData.layoutReservationFrames(timeline_availability.running_reservations)
    var userEntitlementGroupsForModel = TimelinePreprocessData.userEntitlementGroupsForModel(timeline_availability)
    var entitlementQuantities = TimelinePreprocessData.entitlementQuantities(timeline_availability, relevantItemsCount)
    var reservationsInGroups = TimelinePreprocessData.reservationsInGroups(timeline_availability, entitlementQuantities, lastMoment, relevantItemsCount)
    var calculateChanges = TimelinePreprocessData.changesDates(timeline_availability)
    var changesAlgorithm = TimelinePreprocessData.changesAlgorithm(timeline_availability, calculateChanges, userEntitlementGroupsForModel, relevantItemsCount)
    var changesForDays = TimelinePreprocessData.changesForDays(timeline_availability, lastMoment, changesAlgorithm, relevantItemsCount)
    var invalidReservations = TimelinePreprocessData.invalidReservations(timeline_availability, changesAlgorithm, relevantItemsCount)

    return {
      firstMoment: firstMoment,
      lastMoment: lastMoment,
      numberOfDays: numberOfDays,
      relevantItemsCount: relevantItemsCount,
      totalCounts: totalCounts,
      reservationCounts: reservationCounts,
      unusedCounts: unusedCounts,
      allLayoutedReservationFrames: allLayoutedReservationFrames,
      userEntitlementGroupsForModel: userEntitlementGroupsForModel,
      entitlementQuantities: entitlementQuantities,
      reservationsInGroups: reservationsInGroups,
      calculateChanges: calculateChanges,
      changesAlgorithm: changesAlgorithm,
      changesForDays: changesForDays,
      invalidReservations: invalidReservations
    }

  }
}
