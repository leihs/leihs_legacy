Feature: Rejected order reason on the orders list

  Background:
    Given personas dump is loaded

  @manage_rejected_order_reason
  Scenario: Long reject reason wraps without overflowing the order line
    Given I am Pius
    And a customer for my inventory pool exists
    And a rejected order with a long reject reason exists for the customer
    When I open the orders list
    Then the reject reason is shown on the order line
    And the rejected order line does not overflow horizontally
