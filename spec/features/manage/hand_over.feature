Feature: Hand over

  Background:
    Given personas dump is loaded

  @manage_hand_over
  Scenario: Handing over an item to the same user multiple times should not be possible
    Given I am Pius
    And a customer for my inventory pool exists
    And an item owned by my inventory pool exists
    And the customer has borrowed the item for today
    When I open hand over for the user
    And I try to assign the item for today
    Then I see an error message that the item is already assigned to a contract
    And the reservation line was not created
