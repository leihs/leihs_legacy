Feature: Edit contract line during hand over process

  In order to edit a contract line
  As an Lending Manager
  I want to have functionalities to change a contract reservations time range and quantity

  Background:
    Given I am Pius

  @broken
  Scenario: Change the time range of a single contract line
     When I open a hand over
      And I change a contract reservations time range
     Then the time range of that line is changed

  Scenario: Change the quantity of a single contract line (item line)
    Given I open a hand over with an unassigned item line
      And I change a contract reservations quantity
     Then the contract line was duplicated

  Scenario: Change the time range of multiple contract reservations
     When I open a hand over which has multiple reservations
      And I change the time range for all contract reservations, envolving option and item reservations
     Then the time range for all contract reservations is changed

  Scenario: Change the time range of an option line
     When I open a hand over
      And I add an option to the hand over by providing an inventory code
      And I change the time range for that option
     Then the time range for that option line is changed

  @flapping
  Scenario: Change the quantity of an option line
     When I open a hand over
      And I add an option
      And I change the quantity through the edit dialog
     Then the quantity for that option line is changed
     When I change the quantity through the edit dialog
     Then the quantity for that option line is changed

  @flapping
  Scenario: Change the quantity directly on an option line
     When I open a hand over
      And I add an option
      And I change the quantity right on the line
     Then the quantity for that option line is changed
     When I decrease the quantity again
     Then the quantity for that option line is changed
