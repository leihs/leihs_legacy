
Feature: Basic information for inventory pools

  As a person responsible for managing inventory pools
  I want to be able to change their settings and supply basic information
  So that each inventory pool has all the information and settings they
  need to work efficiently (e.g. opening hours, proper addresses, etc.)

  Scenario: Make basic settings
    Given I am Mike
    When I navigate to the inventory pool manage section
    Then I enter the inventory pool's basic settings as follows:
    | Name |
    | Short Name |
    | E-Mail |
    | Description |
    | Default Contract Note|
    | Print Contracts |
    And I make a note of which page I'm on
    And I save
    Then I see a confirmation that the information was saved
    And the settings are updated
    And I am still on the same page

  @rack
  Scenario: Pflichtfelder der Grundinformationen zusammen prüfen
    Given I am Mike
    When I edit the current inventory pool
    And I leave the following fields empty:
      | Name       |
      | Short Name |
      | E-Mail     |
    And I save
    Then I see an error message

  Scenario Outline: Deselect checkboxes
    Given I am Mike
    And I edit an inventory pool
    When I enable "<checkbox>"
    And I save
    # because of cider (wierd flash displacement)
    And I remove the flash
    ###
    Then "<checkbox>" is enabled
    When I disable "<checkbox>"
    And I save
    # because of cider (wierd flash displacement)
    And I remove the flash
    ###
    Then "<checkbox>" is disabled
    Examples:
      | checkbox                |
      | Print contracts        |
      | Automatic suspension   |

  @rack
  Scenario: Manage workdays
   Given I am Mike
   And I edit my inventory pool settings
   When I randomly set the workdays monday, tuesday, wednesday, thursday, friday, saturday and sunday to open or closed
   And I save
   Then those randomly chosen workdays are saved

  Scenario: Manage holidays
   Given I am Mike
   And I edit my inventory pool settings
   When I set one or more time spans as holidays and give them names
   And I save
   Then the holidays are saved
   And I can delete the holidays

  @rack
  Scenario Outline: Validate each field in inventory pool settings separately
    Given I am Mike
    When I edit the current inventory pool
    And I fill in the following fields in the inventory pool settings:
    | Name       |
    | Short Name |
    | E-Mail     |
    When I leave the field "<field>" in the inventory pool settings empty
    And I save
    Then I see an error message
    And the other fields still contain their data
    Examples:
      | field      |
      | Name       |
      | Short Name |
      | E-Mail     |

  @rack
  Scenario: Automatically suspend users with late contracts
    Given I am Mike
    When I edit the current inventory pool
    When I enable "Automatic suspension"
    Then I have to supply a reason for suspension
    When I save
    Then this configuration is saved
    When a user is suspended automatically due to late contracts
    Then they are suspended for this inventory pool
    And the reason for suspension is the one specified for this inventory pool
    When I disable "Automatic suspension"
    And I save
    Then "Automatic suspension" is disabled

  @rack
  Scenario: Suspend users automatically only if they aren't already suspended
    Given I am Mike
    When on the inventory pool I enable the automatic suspension for users with overdue take backs
    And a user is already suspended for this inventory pool
    Then the existing suspension motivation and the suspended time for this user are not overwritten

