Feature: Automatic email notification

  Background:
    Given the system is configured for the mail delivery as test mode
    And I am Normin

  @rack
  Scenario: Automatic return notification
    Given I have a non overdue take back
    Then the day before the take back I receive a deadline soon email

  @rack
  Scenario: Automatic return notification if delayed
    Given I have an overdue take back
    Then the day after the take back I receive a remember email
    And for each further day I receive an additional remember email

  @rack
  Scenario: Bundled reminder spans multiple overdue visits
    Given I have two overdue take backs with different end dates in the same pool
    When the overdue reminders are sent
    Then one reminder email is sent that is tied to both visits
