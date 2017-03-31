Feature: Defining application settings through web interface

  @rack
  Scenario: The settings are existing
    Given I am Normin
    When I go to the home page
    Then I am on the borrow

  @rack
  Scenario: The settings are missing
    Given I am Normin
    When the settings are not existing
    Then there is an error for the missing settings
    Given I am Ramon
    When I go to the home page
    Then I am on the settings page
