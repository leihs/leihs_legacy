Feature: Inspection using commment templates

  Background:
    Given the basic dataset is ready

  @inspection
  Scenario: Comment templates not shown if not configured
    Given I am Barbara
      And no inspection comment templates exists
      And a request with following data exist
        | key                | value   |
        | user               | Roger   |
    When I open this request
      Then I can edit the inspector comment
      And I do not see the comment template dropdown

  @inspection
  Scenario: Comment templates shown for inspectors if configured
    Given I am Barbara
      And the following inspection comment templates exists
        | Too expensive         |
        | Only needed next year |
      And a request with following data exist
        | key                | value   |
        | user               | Roger   |
    When I open this request
      Then I can edit the inspector comment
      And I see the comment template dropdown

  @inspection
  Scenario: Using comment templates without custom comment
  Given I am Barbara
    And the following inspection comment templates exists
      | Too expensive         |
      | Only needed next year |
    And a request with following data exist
      | key                | value   |
      | user               | Roger   |
  When I open this request
    Then I can edit the inspector comment
    And I see the comment template dropdown
    And I choose the comment template "Too expensive"
    And I save the inline form
  Then the request has to following values saved in the database
    | key                | value          |
    | inspection_comment | Too expensive  |

  @inspection
  Scenario: Using comment templates in addition to custom comment
    Given I am Barbara
      And the following inspection comment templates exists
        | Too expensive         |
        | Only needed next year |
      And a request with following data exist
        | key                | value   |
        | user               | Roger   |
    When I open this request
      Then I can edit the inspector comment
      And I see the comment template dropdown
      And I fill in the following fields
        | key                | value                 |
        | Inspection comment | My Individual Comment |
      And I choose the comment template "Too expensive"
      And I save the inline form
    Then the request has to following values saved in the database
      | key                | value                                |
      | inspection_comment | Too expensive; My Individual Comment |
