Feature: Buildings

  Background:
    Given personas dump is loaded
    And I am Gino
    When I visit "/admin/buildings"

  @leihs_admin_buildings
  Scenario: Listing existing buildings
    Then I see a list of all buildings
    And the buildings are sorted alphabetically
    And the first row contains name of the building
    And the first row contains code of the building
    And the first row contains rooms count of the building
    And the first row contains items count of the building
    And the general building row contains the general label
    And the general building row is highlighted

  @leihs_admin_buildings
  Scenario: Creating existing buildings with required values
    When I create a new building providing all required values
    And I save
    Then I see a list of buildings
    And I see the new building
    And the new building was created in the database
    And a general room for this building was created in the database

  @leihs_admin_buildings
  Scenario: Creating existing buildings omitting required values
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

  @leihs_admin_buildings 
  Scenario: Deleting existing buildings
    Given there is a deletable building
    When I visit "/admin/buildings"
    When I delete a building
    Then I see a list of buildings
    And I don't see the deleted building
    And the building was deleted from the database
    And its general room was deleted from the database too
