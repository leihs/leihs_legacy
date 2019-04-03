Feature: Order mails

  Background:
    Given personas dump is loaded

  @borrow_order_mails
  Scenario: Submitting an order should trigger sending of the appropriate mails
    Given I am logged in as customer
    And 'deliver_received_order_notifications' is set to true in admin settings
    And there exists pool A
    And I have access to pool A
    And there is a model A
    And pool A has a borrowable item for model A
    And there exists pool B
    And I have access to pool B
    And there is a model B
    And pool B has a borrowable item for model B
    And the customer has an unsubmitted reservation for model A and pool A
    And the customer has an unsubmitted reservation for model B and pool B
    When I open the current order page
    And I fill in the purpose
    And I click on submit button
    Then I see a notification message
    And 4 mails has been sent
    And one mail with received template was sent to pool A
    And one mail with received template was sent to pool B
    And one mail with submitted template for pool A was sent to the customer
    And one mail with submitted template for pool B was sent to the customer
