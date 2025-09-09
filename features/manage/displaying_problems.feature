
Feature: Displaying problems

  Background:
    Given I am Pius

  Scenario: Showing problems in an order when a model is not avaiable
    Given I edit the latest problematic order
    And a model is no longer available
    ################################################################
    # on Cider the flash message gets sometimes displaced and covers
    # other relevant elements, that's why it has to be closed first
    And I close the flash message if visible
    ################################################################
    Then I see any problems displayed on the relevant reservations
     And the problem is displayed as: "Nicht verfügbar 2(3)/7"
     And "2" are available for the user, also counting availability from groups the user is member of
     And "3" are available in total, also counting availability from groups the user is not member of
     And "7" are in this inventory pool (and borrowable)

  @flapping
  Scenario: Showing problems in an order when taking back a defective item
    Given I take back an item
    And one item is defective
     Then the affected item's line shows the item's problems
     And the problem is displayed as: "Gegenstand ist defekt"

  @flapping
  Scenario: Showing problems when handing over a defective item
    Given I am doing a hand over
    And one item is defective
     Then the affected item's line shows the item's problems
     And the problem is displayed as: "Gegenstand ist defekt"

  Scenario: Displaying problems with incomplete items during take back
    Given I take back an item
     And one item is incomplete
     Then the affected item's line shows the item's problems
     And the problem is displayed as: "Gegenstand ist unvollständig"

  @flapping
  Scenario: Showing problems when handing over an item that is not borrowable
    Given I am doing a hand over
    And one item is not borrowable
     Then the affected item's line shows the item's problems
     And the problem is displayed as: "Gegenstand nicht ausleihbar"

  Scenario: Showing problems when taking back an item that is not borrowable
    Given I take back an item
    And one item is not borrowable
    Then the affected item's line shows the item's problems
    And the problem is displayed as: "Gegenstand nicht ausleihbar"

  Scenario: Showing problems when item is not available while handing over
    # this cucumber global spaghetti steps drive me CRAZY!!! #############
    # please don't change for your own sake, until we trash this cucumber shit
    Given test data setup XXX
      And I open a hand over XXX
    ######################################################################
      And a model is no longer available
     Then the last added model line shows the line's problem
      And the problem is displayed as: "Nicht verfügbar 2(3)/7"
      And "2" are available for the user, also counting availability from groups the user is member of
      And "3" are available in total, also counting availability from groups the user is not member of
      And "7" are in this inventory pool (and borrowable)

  @unstable
  Scenario: Showing problems when item is not available while taking back
    Given I open a take back, not overdue
     And a model is no longer available
     Then I see any problems displayed on the relevant reservations
      And the problem is displayed as: "Nicht verfügbar 2(3)/7"
      And "2" are available for the user, also counting availability from groups the user is member of
      And "3" are available in total, also counting availability from groups the user is not member of
      And "7" are in this inventory pool (and borrowable)

  @flapping
  Scenario: Problemanzeige bei Aushändigung wenn Gegenstand unvollständig
    Given I am doing a hand over
    And one item is incomplete
    Then the affected item's line shows the item's problems
    And the problem is displayed as: "Gegenstand ist unvollständig"

  Scenario: Showing problems during take back if overdue
    Given I take back a late item
    Then the affected item's line shows the item's problems
    And the problem is displayed as: "Überfällig seit 6 Tagen"
