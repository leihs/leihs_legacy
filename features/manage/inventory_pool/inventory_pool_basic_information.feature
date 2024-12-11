Feature: Basic information for inventory pools

  @rack
  Scenario: Automatically suspend users with late contracts
    Given I am Mike
    When I enable automatic suspension and provide a reason for suspension
    When a user is suspended automatically due to late contracts
    Then they are suspended for this inventory pool
    And the reason for suspension is the one specified for this inventory pool

  @rack
  Scenario: Suspend users automatically only if they aren't already suspended
    Given I am Mike
    When on the inventory pool I enable the automatic suspension for users with overdue take backs
    And a user is already suspended for this inventory pool
    Then the existing suspension motivation and the suspended time for this user are not overwritten
