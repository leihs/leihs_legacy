Feature: List of returns

  Background:
    Given personas dump is loaded

  @borrow_list_of_returns
  Scenario: Each reservation line should display start and end date
    Given I am logged in as a customer
    And I have a signed contract
    When I open the list of returns page
    Then each reservation line displays start and end date

