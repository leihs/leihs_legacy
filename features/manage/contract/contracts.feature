Feature: List of contracts

  Background:
    Given I am Andi

  Scenario: Visible tabs
    When I open the tab "Contracts"
    Then I see the tabs:
      | All    |
      | Open   |
      | Closed |
    And the checkbox "To be verified" is already checked and I can uncheck

  Scenario: View contracts
    When I open the tab "Contracts"
    Then I can view "open" contracts
    And I can view "closed" contracts
    And I can view "all" contracts
    And I can open the contract of any contract line
    And I can open the picking list of any contract line
    And I can open the value list of any contract line

  Scenario: Contract displays total price
    When I open the tab "Contracts"
    And I can open the contract of any contract line
    Then I see the total price section on the contract
    And the total price matches the sum of all reservation prices

  Scenario Outline: A list whose reservations fail to load can be retried
    Given the next reservations request of a list fails once
    When I open the tab "<tab>"
    Then the loading icon is replaced by a retry control
    When I retry loading the first page
    Then the list shows its lines
    And the reservations were requested again

    Examples:
      | tab       |
      | Orders    |
      | Contracts |
