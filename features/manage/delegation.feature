Feature: Delegation

  Scenario: Choosing contact person when handing over
    Given I am Pius
    And there is a hand over for a delegation with assigned items
    And I open this hand over
    When I finish this hand over
    Then I have to specify a contact person

  Scenario: Switching an order from a delegation to a normal user while handing over
    Given I am Pius
    And I open a hand over for a delegation
    When I pick a user instead of a delegation
    Then the hand over shows the user

  Scenario: Switching an order from a normal user to a delegation when handing over
    Given I am Pius
    And I open a hand over
    When I pick a delegation instead of a user
    Then the order shows the delegation

  Scenario: Tooltip display
    Given I am Pius
    When I search for a delegation
    And I click on the delegation name
    Then the tooltip shows name and responsible person for the delegation

  Scenario: Global search
    Given I am Pius
    And there exists a delegation with 'Julie' in its name
    And Julie is in a delegation
    When I search for 'Julie'
    Then I see all results in the users box for users matching Julie
    And I see all results in delegations box for delegations matching Julie or delegations having members matching Julie
