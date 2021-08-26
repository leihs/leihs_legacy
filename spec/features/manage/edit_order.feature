Feature: Edit order

  Background:
    Given personas dump is loaded

  @manage_edit_order
  Scenario: Don't find models without any items
    Given I am Pius
    And a customer for my inventory pool exists
    And a submitted order for the customer exists
    And a model exists
    When I open the order
    And I enter the model's name in the "Add" input field
    Then the results of the autocomplete menu are empty

  @manage_edit_order
  Scenario: Don't find models with retired items
    Given I am Pius
    And a customer for my inventory pool exists
    And a submitted order for the customer exists
    And an item owned by my inventory pool exists
    And the item is borrowable
    And the item is retired
    When I open the order
    And I enter the item's model name in the "Add" input field
    Then the results of the autocomplete menu are empty
