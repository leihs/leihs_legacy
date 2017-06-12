Feature: List of pickups

  Background:
    Given personas dump is loaded

  @borrow_list_of_pickups
  Scenario: Each reservation line should display start and end date
    Given I am logged in as customer
    And I have an approved order
    When I open the list of pickups page
    Then each reservation line displays start and end date
