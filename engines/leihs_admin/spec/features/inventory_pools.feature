Feature: Administer inventory pools

  As an administrator
  I want to have admin tools spanning the entire system
  So that I can create, update and edit inventory pools

  Background:
    Given personas dump is loaded

  @leihs_admin_inventory_pools
  Scenario: List of inventory pools
    Given I am Gino
    When I navigate to the admin area
    Then I see the list of all active inventory pools sorted alphabetically
    And each line displays the inventory pool's name
    And each line displays the inventory pool's short name
    And each line displays the inventory pool's active state

  @leihs_admin_inventory_pools
  Scenario: Choosing an inventory pool
    Given I am Gino
    When I navigate to the admin area
    Then I see the list of all inventory pools
    When I click the navigation toggler
    Then I see all managed inventory pools
    And the list of inventory pools is sorted alphabetically

  @leihs_admin_inventory_pools
  Scenario: Creating an initial inventory pool
    Given I am Gino
    And I navigate to the admin area
    When I create a new inventory pool in the admin area's inventory pool tab
    And I enter name, shortname and email address
    And I save
    Then I see the list of all inventory pools
    And I see a notification message
    And the inventory pool is saved

  @leihs_admin_inventory_pools
  Scenario Outline: Required fields when creating an inventory pool
    Given I am Ramon
    When I create a new inventory pool in the admin area's inventory pool tab
    And I don't fill in <required_field>
    And I save
    Then I see an error message
    And the inventory pool is not created
    Examples:
      | required_field |
      | Name           |
      | Short Name     |
      | E-Mail         |

  @leihs_admin_inventory_pools
  Scenario: Editing inventory pool
    Given I am Ramon
    When I edit in the admin area's inventory pool tab an existing inventory pool
    And I change name, shortname and email address
    And I save
    Then the inventory pool is saved

  @leihs_admin_inventory_pools
  Scenario: Delete inventory pool
    Given I am Ramon
    When I delete an existing inventory pool in the admin area's inventory pool tab
    Then the inventory pool is removed from the list
    And the inventory pool is deleted from the database

  @leihs_admin_inventory_pools
  Scenario: Automatically grant access to new users
    Given I am Gino
    And multiple inventory pools are granting automatic access
    And I open the list of users
    When I have created a user with login "username" and password "password"
    Then the newly created user has 'customer'-level access to all inventory pools that grant automatic access

  @leihs_admin_inventory_pools
  Scenario Outline: Deactivating an inventory pool is not possible if there are orders or signed contracts
    Given I am Ramon
    And there exists an inventory pool with "<order type>"
    When I open the edit page for an inventory pool
    And I select "No" from "Active?"
    And I save
    Then I see an error message regarding the deactivation of inventory pool
    And the inventory pool remains active
    Examples:
      | order type        |
      | submitted order   |
      | approved order    |
      | signed contract   |

  @leihs_admin_inventory_pools
  Scenario Outline: Deactivating an inventory pool is possible if there are only unsubmitted orders, rejected orders or closed contracts
    Given I am Ramon
    And there exists an inventory pool with "<order type>"
    And the inventory pool does not have any unretired items
    When I open the edit page for an inventory pool
    And I select "No" from "Active?"
    And I save
    Then I see a success message
    And the inventory pool became inactive
    Examples:
      | order type          |
      | unsubmitted order   |
      | rejected order      |
      | closed contract     |

  @leihs_admin_inventory_pools
  Scenario: Deactivating an inventory pool destroys unsubmitted orders
    Given I am Ramon
    And there exists an inventory pool with "unsubmitted order"
    And the inventory pool does not have any unretired items
    When I open the edit page for an inventory pool
    And I select "No" from "Active?"
    And I save
    Then I see a success message
    And the inventory pool became inactive
    And there is no unsubmitted order for the deactivated inventory pool

  @leihs_admin_inventory_pools
  Scenario: Exclusion of inactive inventory pools in the topbar dropdown list
    Given I am Gino
    And I navigate to the admin area
    And there exists an inactive inventory pool I have access to as "inventory_manager"
    When I click on the sections dropdown toggle
    Then I don't see the inactive inventory pool in the list

  @leihs_admin_inventory_pools
  Scenario Outline: Deactivating an inventory pool is not possible if there are not retired items
    Given I am Ramon
    And there exists an inventory pool
    And the inventory pool <has or owns> an unretired item
    When I open the edit page for an inventory pool
    And I select "No" from "Active?"
    And I save
    Then I see an error message regarding the deactivation of inventory pool
    And the inventory pool remains active
    Examples:
      | has or owns           |
      | has but doesn't own   |
      | owns but doesn't have |

  @leihs_admin_inventory_pools
  Scenario: Filtering active and inactive inventory pools
    Given I am Ramon
    And there exists an active inventory pool
    And there exists an inactive inventory pool
    And I navigate to the inventory pools page
    Then the activity filtering is set to "active"
    And I can see the active inventory pool
    And I can not see the inactive inventory pool
    When I filter for "All" activity
    Then the activity filtering is set to "all"
    And I can see the active inventory pool
    And I can see the inactive inventory pool
    When I filter for "Inactive" activity
    Then the activity filtering is set to "inactive"
    And I can not see the active inventory pool
    And I can see the inactive inventory pool

  @leihs_admin_inventory_pools
  Scenario: Regrant inventory manager access
    Given I am Ramon
    And there exists an active inventory pool
    And there exists a user
    And the user had access to the pool as inventory manager
    When I open the edit page for the active inventory pool
    And I add the user as inventory manager of the pool
    And I save
    Then I see a success message
    And the user has inventory manager access to the pool
