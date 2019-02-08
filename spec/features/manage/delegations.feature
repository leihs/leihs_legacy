Feature: Delegations

  Background:
    Given personas dump is loaded
    And I am Mike

  @manage_delegations
  Scenario: Remove delegation member with stuff in basket (unsubmitted reservations)
    Given there exists an inventory pool
    And there exists a model with items
    And there is a customer delegation for the current pool
    And there is a customer for the current pool
    And the user is a member of the delegation
    And the user has a session for the delegation
    And the user has unsubmitted reservation for the delegation
    And the user has rejected reservation for the delegation
    And the user has closed reservation for the delegation
    And the user has a submitted reservation
    When I open the edit page of the delegation
    And I remove the user
    And I save
    Then I see a notification message
    And the user is no longer member of the delegation
    And the user does not have any unsubmitted reservations for the delegation
    And the user has still the same rejected reservation for the delegation
    And the user has still the same closed reservation for the delegation
    And the user has still the same submitted reservation
    And the user does not have any session for the delegation anymore

  @manage_delegations
  Scenario: Removing a member with open reservations for the delegation raises error
    Given there exists an inventory pool
    And there exists a model with items
    And there is a customer delegation for the current pool
    And there is a customer for the current pool
    And the user is a member of the delegation
    And the user has submitted reservation for the delegation
    When I open the edit page of the delegation
    And I remove the user
    And I save
    Then I see an error message
    And the user is still member of the delegation
    And the user has still the same submitted reservation for the delegation
