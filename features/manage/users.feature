Feature: Manage users

  Background:
    Given I am Mike

  Scenario: Delete user from an inventory pool is not possible
    Given I pick a user without access rights, orders or contracts
    When I am looking at the user list in any inventory pool
    Then the delete button for that user is not present

  @rack
  Scenario: Remove access as inventory manager
    And I am editing a user who has access to and no items from an inventory pool
    When I remove their access
    And I save
    Then the user has no access to the inventory pool


  Scenario: Change access as inventory manager
    And I edit a user who is customer in any inventory pool
    Then I can only choose the following roles
      | No access          |
      | Customer           |
      | Group manager      |
      | Lending manager    |
      | Inventory manager  |
    When I change the access level to "inventory manager"
    And I save
    Then the user has the role "inventory manager"

  Scenario: Alphabetical sorting of users within an inventory pool
    And I am looking at the user list in any inventory pool
    Then users are sorted alphabetically by first name
