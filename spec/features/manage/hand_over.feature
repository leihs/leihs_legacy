Feature: Hand over

  Background:
    Given personas dump is loaded

  @manage_hand_over @flapping
  Scenario: Handing over an item to the same user multiple times should not be possible
    Given I am Pius
    And a customer for my inventory pool exists
    And an item owned by my inventory pool exists
    And the customer has borrowed the item for today
    When I open hand over for the user
    And I try to assign the item for today
    Then I see an error message that the item is already assigned to a contract
    And the reservation line was not created

  @manage_hand_over
  Scenario: Handing over items and licenses by model search
    Given I am Pius
    And a customer for my inventory pool exists
    And an item owned by my inventory pool exists
    And a license owned by my inventory pool exists
    When I open hand over for the user
    And I enter the item's model name in the "Add/Assign" input field
    And I choose the item's model name from the displayed dropdown
    Then a reservation line for the item's model name was added
    When I enter the license's model name in the 'Add/Assign' input field
    And I choose the license's model name from the displayed dropdown
    Then a reservation line for the license's model name was added
    When I assign the item to its model line
    And I assign the license to its model line
    And I click on "Hand Over Selection"
    And I enter the purpose
    And I click on "Hand Over"
    When I switch to the contract window
    Then the contract includes the inventory code of the item
    And the contract includes the inventory code of the license
