Feature: Manage users

  Scenario: Displaying a user and their roles in lists
    Given I am inventory manager or lending manager
    And a user with assigned role appears in the user list
    Then I see the following information about the user, in order:
      |attr |
      |First name/last name|
      |Phone number|
      |Role|

  Scenario: Not displaying a user's role in lists if that user doesn't have a role
    Given I am inventory manager or lending manager
    And a user without assigned role appears in the user list
    Then I see the following information about the user, in order:
      |attr |
      |First name/last name|
      |Phone number|
      |Role|

  Scenario: Displaying a user in a list with their assigned roles and suspension status
    Given I am inventory manager or lending manager
    And a suspended user with assigned role appears in the user list
    Then I see the following information, in order:
      |attr |
      |First name/last name|
      |Phone number|
      |Role|
      |Suspended until dd.mm.yyyy|

  @rack
  Scenario: Role 'lending manager'
    Given I am a lending manager
    When I open the inventory
    Then I can create new items
    And these items cannot be inventory relevant
    And I can create options
    And I can retire items if my inventory pool is their owner and they are not inventory relevant

  @rack
  Scenario: Role 'inventory manager'
    Given I am an inventory manager
    Then I can create new models
    And I can create new items
    And these items can be inventory relevant
    And I can make another inventory pool the owner of the items
    And I can retire these items if my inventory pool is their owner
    And I can unretire items if my inventory pool is their owner
    And I can specify workdays and holidays for my inventory pool
    And I can do everything a lending manager can do
    When I don't choose a responsible department when creating or editing items
    Then the responsible department is the same as the owner
