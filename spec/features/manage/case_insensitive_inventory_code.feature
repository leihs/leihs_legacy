Feature: Case insensitive inventory code feature

  Background:
    Given personas dump is loaded

  @manage_case_insensitive_inventory_code
  Scenario: Creating an item with case-insensitive existing inventory code should not be possible
    Given I am Mike
    And there is an item with uppercase inventory code in the current pool
    And I open the page for creating a new item
    When I enter the inventory code of this item in lowercase
    And I select a model
    And I select a supply category
    And I choose a building
    And I choose a room
    And I save
    Then I see an error message in regards to already existing inventory code
    And the item was not saved

  @manage_case_insensitive_inventory_code
  Scenario: Assigning an item via inventory code in hand over is case-insensitive
    Given I am Pius
    And there is an item with uppercase inventory code in the current pool
    And there is a customer in the current pool
    When I open hand over for this customer
    And I add this assign to the hand over
    Then the new item line was added to the hand over
    And the new item line was created in the data base
