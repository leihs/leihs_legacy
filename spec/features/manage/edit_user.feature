Feature: Edit user

  Background:
    Given personas dump is loaded

  @manage_edit_user
  Scenario: Removing last group from the user
    Given I am Mike
    And there is a customer for the current pool
    And there is a group in the current pool
    And the user belongs to this group
    When open the edit page of the user
    And I remove the group
    And I save
    Then I see a notification message
    When open the edit page of the user
    Then the user does not belong to any group
