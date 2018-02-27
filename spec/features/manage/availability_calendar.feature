Feature: Availability Calendar

Background:
  Given personas dump is loaded

@manage_availability_calendar
Scenario: Availabilty of items assigned to a group
  Given I am Pius
    And there is a Group "Filmerei"
    And there is a Model "Camera"
    And this Model has 10 lendable Items
    And those Items are all asigned to this Group
    And 5 of those Items are already lent
    And 2 of those Items are in the current Order from a user belonging to this Group

  When I go to edit this Order

  Then the number on the left hand side shows "2 / 5"
    And the timeline shows "7 5 0 0" assigned of "10" available for the group
    And the calendar shows an availabilty of "5"
