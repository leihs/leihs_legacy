Feature: Fields

  Background:
    Given personas dump is loaded
    And I am Gino

  @leihs_admin_fields
  Scenario: Listing all fields
    Given I open the fields page
    Then I see all fields
    And the data of all fields is readonly
    And the activate checkbox of a non-required field is enabled
    But the activate checkbox of a required field is disabled

  @leihs_admin_fields
  Scenario: Activating / deactivating fields
    Given I open the fields page
    And there is at least one inactive field
    And I store the information about the active state of all fields
    When I deactivate an active field
    And I activate an inactive field
    And I update
    Then I see a success message that the fields have been updated successfully
    And the formerly active field is now inactive
    And the formerly inactive field is now active
    And all other fields remained unchanged
