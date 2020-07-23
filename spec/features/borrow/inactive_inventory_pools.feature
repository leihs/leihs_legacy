Feature: Inactive inventory pools

  Background:
    Given personas dump is loaded

  @borrow_inactive_inventory_pools
  Scenario: Inactive pools are not shown in the list of customer's pools
    Given I am logged in as customer
    And there exists an inventory pool
    And I have an access as customer to this inventory pool
    And this inventory pool has a borrowable item
    And there exists an inactive inventory pool
    And the inactive inventory pool has a borrowable and retired item
    And I have an access as customer to the inactive inventory pool
    When I open inventory pools page
    Then I don't see the inactive inventory pool

  @borrow_inactive_inventory_pools
  Scenario: Models of items in an inactive pool are not displayed in the model list
    Given I am logged in as customer
    And there exists a category
    And there exists an active inventory pool
    And the active inventory pool has a borrowable item
    And the model of the item from the active pool belongs to the category
    And I have an access as customer to the active inventory pool
    And there exists an inactive inventory pool
    And the inactive inventory pool has a borrowable and retired item
    And the model of the item from the inactive pool belongs to the category
    And I have an access as customer to the inactive inventory pool
    When I open the model list for the category
    Then I see the model from the active inventory pool
    But I don't see the model from the inactive inventory pool

  @borrow_inactive_inventory_pools
  Scenario: Inactive inventory pools are not displayed in the filter of the model list
    Given I am logged in as customer
    And there exists a category
    And there exists an active inventory pool
    And the active inventory pool has a borrowable item
    And the model of the item from the active pool belongs to the category
    And I have an access as customer to the active inventory pool
    And there exists an inactive inventory pool
    And the inactive inventory pool has a borrowable and retired item
    And the model of the item from the inactive pool belongs to the category
    And I have an access as customer to the inactive inventory pool
    When I open the model list for the category
    Then the inactive inventory pool is not displayed in the pool selection dropdown of the filter

  @borrow_inactive_inventory_pools
  Scenario: Inactive pools are not displayed in the booking calendar
    Given I am logged in as customer
    And there exists a category
    And there exists an active inventory pool
    And the active inventory pool has a borrowable item
    And the model of the item from the active pool belongs to the category
    And I have an access as customer to the active inventory pool
    And there exists an inactive inventory pool
    And the inactive inventory pool has a borrowable and retired item
    And the model of the item from the inactive pool belongs to the category
    And I have an access as customer to the inactive inventory pool
    When I open the model list for the category
    And I open the booking calendar for the model from the active inventory pool
    Then the inactive inventory pool is not displayed in the pool selection dropdown
