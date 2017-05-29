Feature: List of orders

  Background:
    Given personas dump is loaded

  @borrow_list_of_orders
  Scenario: Each reservation line should display start and end date
    Given I am logged in as a customer
    And I have a submitted order
    When I open the list of orders page
    Then each reservation line displays start and end date
