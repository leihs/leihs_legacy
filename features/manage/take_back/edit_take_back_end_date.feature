Feature: Edit take back end date

  In order to extend the lending time of a customer
  As an Lending Manager
  I want to have functionalities to change a take backs end date

  Background:
    Given I am Pius

  @flapping
  Scenario: Change the time range of a single take back line
     When I open a take back
      And I change a contract line end date
     Then the end date of that line is changed
     And the start date of that line is not changed

  @flapping
  Scenario: Change the time range of a single take back option line handed over in the past
    When I open a take back with at least an option handed over before today
    And I change an option line end date
    Then the end date of that line is changed
    And the start date of that line is not changed

  Scenario: Change the time range of multiple contract reservations
     When I open a take back which has multiple reservations
      And I change the end date for all contract reservations, envolving option and item reservations
     Then the end date for all contract reservations is changed
