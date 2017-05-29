Feature: Current order

  Background:
    Given personas dump is loaded

  @borrow_current_order
  Scenario: Each reservation line should display start and end date
    Given I am logged in as a customer
    And I have an unsubmitted order
    When I open the page for this order
    Then each reservation line displays start and end date
