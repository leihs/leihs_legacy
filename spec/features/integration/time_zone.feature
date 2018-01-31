Feature: Configuring the system timezone through the database
  As a system administrator
  I want to set up my leihs instance to use times from my own timezone
  so that times are represented in a way that makes sense for my users.

  @time_zone
  Scenario: Representing a date and time on automatically managed time fields (created_at)
    Given personas dump is loaded
    And I am Gino
    When I open the settings page
    And I set time zone to "Moscow"
    And I click on "Save Settings"
    Then I see a notice message
    And the time zone is now set to "Moscow"
    When I am Mike
    And I open the create model page
    And I fill in the model name
    And I save
    Then I see a success message
    And the model was created in the database
    And the model's created_at attribute has time zone "Moscow"
