Feature: Inactive inventory pools

  Inactive inventory pools should be excluded from everywhere

  Background:
    Given personas dump is loaded

  @manage_inactive_inventory_pools
  Scenario Outline: Exclusion of inactive inventory pools in the topbar dropdown list
    Given I am logged in as <role>
    And there exists an inactive inventory pool I have access to as "<role>"
    When I hover over the current inventory pool in navigation bar
    Then I don't see the inactive inventory pool in the list
    Examples:
      | role              |
      | group manager     |
      | lending manager   |
      | inventory manager |

  @manage_inactive_inventory_pools
  Scenario: Exclusion of inactive inventory pools in the autocomplete dropdown on item edit page
    Given I am logged in as inventory manager
    And there is an item which is owned by the current inventory pool
    And there exists an inactive inventory pool
    When open the edit page for the item
    And I fill in the name of the inactive inventory pool for "Responsible department"
    Then there is no autocomplete menu visible

  @manage_inactive_inventory_pools
  Scenario: Exclusion of inactive inventory pools in the autocomplete dropdown on inventory helper page
    Given I am logged in as inventory manager
    And there is an item which is owned by the current inventory pool
    And there exists an inactive inventory pool
    When open the inventory helper page
    And choose the responsible department via field select box
    And I fill in the name of the inactive inventory pool for "Responsible department"
    Then there is no autocomplete menu visible

  @manage_inactive_inventory_pools
  Scenario: Exclusion of inactive inventory pools from inventory list
    Given I am logged in as inventory manager
    And there exists an inactive inventory pool I have access to as "inventory manager"
    And there is a retired item which is owned by the the current pool but in responsibility of the inactive inventory pool
    When I open the inventory list
    And I enter the inventory code of the item in the inventory search field
    Then no item is found
    And I there is not possibility to choose the inactive inventory pool from the inventory pools select field
