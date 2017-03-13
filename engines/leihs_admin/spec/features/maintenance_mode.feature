
Feature: Maintenance mode

  As admin I want to have the possibility to disable the sections "Manage" and "Lending"
  in case of maintenance work and to display a corresponding message to the user.

  Background:
    Given personas dump is loaded
    And I am Gino

  @leihs_admin_maintenance_mode @javascript
  Scenario: Disabling the manage section
    Given I am in the system-wide settings
    When I choose the function "Disable manage section"
    Then I have to enter a note
    When I enter a note for the "manage section"
    And I save
    Then the settings for the "manage section" were saved
    And the "manage section" is disabled for users
    And users see the note that was defined

  @leihs_admin_maintenance_mode @javascript
  Scenario: Disabling the borrow section
    Given I am in the system-wide settings
    When I choose the function "Disable borrow section"
    Then I have to enter a note
    When I enter a note for the "borrow section"
    And I save
    Then the settings for the "borrow section" were saved
    And the "borrow section" is disabled for users
    And users see the note that was defined

  @leihs_admin_maintenance_mode @javascript
  Scenario: Enabling the manage section
    Given the "manage section" is disabled
    And I am in the system-wide settings
    When I deselect the "disable manage section" option
    And I save
    Then the "manage section" is not disabled for users
    And the note entered for the "manage section" is still saved

  @leihs_admin_maintenance_mode @javascript
  Scenario: Enabling the borrow section
    Given the "borrow section" is disabled
    And I am in the system-wide settings
    When I deselect the "disable borrow section" option
    And I save
    Then the "borrow section" is not disabled for users
    And the note entered for the "borrow section" is still saved
