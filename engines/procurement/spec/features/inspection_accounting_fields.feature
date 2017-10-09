Feature: Inspection using accounting fields

  Background:
    Given the basic dataset is ready

  @inspection
  Scenario: Request default accounting type is "Beschaffung", shows correct fields
    Given I am Barbara
      And no inspection comment templates exists
      And a request with following data exist
        | key                | value   |
        | user               | Roger   |
    When I open this request
    Then I see the accounting type is "Beschaffung"
      And I see the "Kostenstelle" of the sub category
      And I do not see the "Sachkonto" of the sub category
      And I do not see the field "Innenauftrag"


  @inspection
  Scenario: Request of type "Investition", shows correct fields
    Given I am Barbara
      And a request with following data exist
        | key                | value   |
        | user               | Roger   |
      And I open this request
    When I change the accounting type to "Investition"
    Then I see the "Sachkonto" of the sub category
      And I do not see the "Kostenstelle" of the sub category
      And I see the field "Innenauftrag"
      And the field "Innenauftrag" is marked red

  @inspection
  Scenario: Changing Request type to "Investition" and entering "Innenauftrag"
    Given I am Barbara
      And a request with following data exist
        | key                | value   |
        | user               | Roger   |
      And I open this request
    When I change the accounting type to "Investition"
      And I fill in the following fields
        | key             | value     |
        | Innenauftrag    | 234234234 |
      And I save the inline form
    Then the request has to following values saved in the database
        | key                   | value      |
        | accounting_type       | investment |
        | internal_order_number | 234234234  |

  @inspection
  Scenario: Accounting fields only visible for Inspectors ("Beschaffung")
    Given I am Roger
      And a request with following data exist
        | key                | value      |
        | user               | Roger      |
        | accounting type    | aquisition |
    When I open this request
    Then I do not see any accounting type fields

  @inspection
  Scenario: Accounting fields only visible for Inspectors ("Investition")
    Given I am Roger
      And a request with following data exist
      | key                   | value      |
      | user                  | Roger      |
      | accounting type       | investment |
      | internal order number | 123456789  |
    When I open this request
    Then I do not see any accounting type fields
