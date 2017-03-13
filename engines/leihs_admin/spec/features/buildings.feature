Feature: Buildings

  Background:
    Given personas dump is loaded
    And I am Gino
    When I visit "/admin/buildings"

  @leihs_admin_buildings
  Scenario: Listing existing buildings
    Then I see a list of buildings

  @leihs_admin_buildings
  Scenario: Creating existing buildings
    When I create a new building providing all required values
    And I save
    Then I see a list of buildings
    And I see the new building

  @leihs_admin_buildings
  Scenario: Creating existing buildings
    When I create a new building not providing all required values
    And I save
    Then I see an error message
    And I see the building form

  @leihs_admin_buildings
  Scenario: Editing existing buildings
    When I edit an existing building
    And I save
    Then I see a list of buildings
    And I see the edited building

  @leihs_admin_buildings @javascript @browser
  Scenario: Deleting existing buildings
    Given there is a deletable building
    When I visit "/admin/buildings"
    When I delete a building
    Then I see a list of buildings
    And I don't see the deleted building
