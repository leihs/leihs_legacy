Feature: Take back

  Background:
    Given personas dump is loaded

  @manage_take_back
  Scenario: Taking back all items of a contract should close it
    Given I am Pius
    And there exists an open contract
    When I open the take back page for the user of this contract
    And I select all lines
    And I click on "Take Back Selection"
    And within modal dialog I click on "Take Back"
    Then I see "Take back completed"
    And the contract is in state "closed"
    And all the reservations of the contract are "closed"
