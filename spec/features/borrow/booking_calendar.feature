Feature: Borrow booking calendar

  Background:
    Given personas dump is loaded

  @borrow_booking_calendar
  Scenario: Creating an unsumbitted reservation exceeding the maximum reservation time not possible
    Given I am logged in as customer
    And there exists an inventory pool
    And I am customer of the pool
    And there is a model
    And there is a borrowable item for the model and the inventory pool
    And the maximum reservation time is set to 5 days
    When I open the model page
    And I click on "Add to order"
    And I set the start date to today
    And I set the end date to today + 5 days
    And I click on "Add"
    Then within the booking calendar I see an error message in regards to the maximum reservation time
    And the reservation has not been created
