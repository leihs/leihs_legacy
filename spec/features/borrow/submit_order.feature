Feature: Submit order

  Background:
    Given personas dump is loaded

  @borrow_submit_order
  Scenario: Failure of submiting an order should display the respective error message
    Given I am logged in as customer
    And I am suspended for a pool I am a customer of
    And there is a borrowable item in this pool
    And I have an unsubmitted order for this pool and the model of this item
    When I open the page for this order
    And I enter the purpose of my order
    And I submit
    Then I see an error message in respect of my suspension
    And the order was not submitted
