window.App.Modules.LineProblems = 

  anyProblems: -> !! @getProblems().length

  getProblems: -> 
    problems = []

    if @model_id?
      reservationsToExclude = if @subreservations? then @subreservations else [@]
      avail = @model().availability()
      maxAvailableForUser = avail.withoutLines(reservationsToExclude).maxAvailableForGroups(@start_date, @end_date, @user().groupIds)
      softOverbooked = _.any avail.changes, (change) =>
        _.any change[2], (allocation) =>
          _.any reservationsToExclude, (line) =>
            allocation.running_reservations? and
            _.include(allocation.running_reservations, line.id) and
            not avail.groupIsIn(line.user().groupIds, allocation.group_id)
      quantity = if @subreservations?
        _.reduce @subreservations, ((mem, l)-> mem + l.quantity), 0
      else
        @quantity

    # OVERDUE
    if moment(@start_date).endOf("day").diff(moment().endOf("day"), "days") < 0 and _.include(["approved", "submitted"], @status) or
       moment(@end_date).endOf("day").diff(moment().endOf("day"), "days") < 0 and @status is "signed"
      days = if _.include(["approved", "submitted"], @status)
        Math.abs moment(@start_date).diff(moment().endOf("day"), "days")
      else
        Math.abs moment(@end_date).diff(moment().endOf("day"), "days")
      problems.push
        type: "overdue"
        message: "#{_jed("Overdue")} #{_jed("since")} #{days} #{_jed(days, "day")}"

    # AVAILABILITY
    else if maxAvailableForUser? and (maxAvailableForUser < quantity or softOverbooked)
      effectiveAvailable = if softOverbooked then maxAvailableForUser - quantity else maxAvailableForUser
      maxAvailableInTotal = avail.withoutLines(reservationsToExclude, true).maxAvailableInTotal(@start_date, @end_date)
      problems.push
        type: "availability"
        message: "#{_jed("Not available")} #{effectiveAvailable}(#{maxAvailableInTotal})/#{avail.total_rentable}"

    if @item()

      # UNBORROWABLE
      unless @item().is_borrowable
        problems.push
          type: "unborrowable"
          message: _jed("Item not borrowable")

      # BROKEN
      if @item().is_broken
        problems.push
          type: "broken"
          message: _jed("Item is defective")

      # BROKEN
      if @item().is_incomplete
        problems.push
          type: "incomplete"
          message: _jed("Item is incomplete")

    return problems
