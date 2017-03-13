Feature: Delegation

  Background:
    Given personas dump is loaded

  @leihs_admin_delegation @javascript @browser
  Scenario: Delete delegation
    Given I am Gino
    And there is a delegation
    And there is no reservation of any kind for this delegation
    And the delegation has no access rights to any inventory pool
    When I open the list of users
    And I search after the delegation
    And I see the line for the delegation
    And I click on the dropdown toggle for the delegation
    And I click on 'Delete' inside the dropdown menu
    And I confirm the dialog
    Then I see a success message
    And the delegation doesn't exist anymore
