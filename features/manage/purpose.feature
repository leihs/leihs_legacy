
Feature: Purpose

  Background:
    Given I am Pius

  Scenario: Places where I see the purpose
    When I edit an order
    Then I see the purpose
    When I open a hand over
    Then I see the assigned purpose on each line

  Scenario: Places where I can edit the purpose
    When I edit an order for a user who is not suspended
    Then I can edit the purpose

  Scenario: Handing over items of which some have purpose
    Given there is an approved and assigned reservation with purpose for a customer
      And I open the hand over page for this customer
     And I select this reservation
     And I add an item to the hand over by providing an inventory code
     And I add an option to the hand over by providing an inventory code
     When I click on hand over
     And I add a purpose
     And I finish the hand over
     Then the contract has the original plus the added purpose

  Scenario: Handing over items that all have a purpose
    Given there is an approved and assigned reservation with purpose for a customer
    And there is another approved and assigned reservation with purpose for a customer
    And I open the hand over page for this customer
    And I select all reservations
    When I click on hand over
    And I finish the hand over
    Then the contract has both the purposes

  Scenario: Handing over without purpose with required purpose
    Given the current inventory pool requires purpose
    When I open a hand over
    And none of the selected items have an assigned purpose
    Then I am told during hand over to assign a purpose
    And only when I assign a purpose
    Then I can finish the hand over

  Scenario: Handing over without purpose without required purpose
    Given the current inventory pool doesn't require purpose
    When I open a hand over
    And none of the selected items have an assigned purpose
    Then I am told during hand over to assign a purpose
    But I do not assign a purpose
    Then I can finish the hand over

  # seems not to be implemented and was passing just by chance
  # Scenario: Hand overs with a few items that don't have a purpose are possible
  #   When I open a hand over
  #   And I click an inventory code input field of an item line
  #   And I select one of those
  #   And I add an item to the hand over by providing an inventory code
  #   And I add an option to the hand over by providing an inventory code
  #   Then I don't have to assign a purpose in order to finish the hand over
