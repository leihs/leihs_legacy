Feature: Submit order

  Background:
    Given personas dump is loaded

  @borrow_submit_order
  Scenario: Failure of submiting an order should display the respective error message
    Given I am logged in as customer
    And I am suspended for a pool I am a customer of
    And there is a borrowable item in this pool
    And I have an unsubmitted reservation for this pool and the model of this item
    When I open the page for this order
    And I enter the purpose of my order
    And I submit
    Then I see an error message in respect of my suspension
    And the order was not submitted

  @borrow_submit_order
  Scenario: Failure of submiting an order with a reservation exceding the maximum reservation time
    Given I am logged in as customer
    And the maximum reservation time is set to 5 days
    And I have an unsubmitted reservation for this pool with reservation time of 6 days
    When I open the page for this order
    And I enter the purpose of my order
    And I submit
    Then I see an error message in respect to the maximum reservation time
    And the order was not submitted

  @borrow_submit_order
  Scenario: Failure of submiting an order with a reservation's start date not respecting reservation advance days
    Given I am logged in as customer
    And the reservation advance days for this pool is set to 1
    And I have an unsubmitted reservation for this pool starting yesterday
    When I open the page for this order
    And I enter the purpose of my order
    And I submit
    Then I see an error message in respect to the reservation advance days
    And the order was not submitted

  @borrow_submit_order
  Scenario: Success of submiting an order with a reservation not exceding the maximum reservation time
    Given I am logged in as customer
    And the maximum reservation time is set to 5 days
    And I have an unsubmitted reservation for this pool with reservation time of 5 days
    And the pool is open on the start and end date of the reservation
    When I open the page for this order
    And I enter the purpose of my order
    And I submit
    Then I see a notification message
    And the order was submitted successfully
