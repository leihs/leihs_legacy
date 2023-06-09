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
