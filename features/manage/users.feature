Feature: Manage users

  Background:
    Given I am Mike

  Scenario: Delete user from an inventory pool is not possible
    Given I pick a user without access rights, orders or contracts
    When I am looking at the user list in any inventory pool
    Then the delete button for that user is not present

  Scenario: Alphabetical sorting of users within an inventory pool
    And I am looking at the user list in any inventory pool
    Then users are sorted alphabetically by first name
