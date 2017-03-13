Feature: Suppliers

  Background:
    Given personas dump is loaded
    And I am Gino
    When I visit "/admin/suppliers"

  @leihs_admin_suppliers
  Scenario: Listing existing suppliers
    Then I see a list of suppliers

  @leihs_admin_suppliers
  Scenario: Creating existing suppliers
    When I create a new supplier providing all required values
    And I save
    Then I see a list of suppliers
    And I see the new supplier

  @leihs_admin_suppliers
  Scenario: Creating existing suppliers
    When I create a new supplier not providing all required values
    And I save
    Then I see an error message
    And I see the supplier form

  @leihs_admin_suppliers
  Scenario: Editing existing suppliers
    When I edit an existing supplier
    And I save
    Then I see a list of suppliers
    And I see the edited supplier

  @leihs_admin_suppliers @javascript @browser
  Scenario: Deleting existing suppliers
    Given there is a deletable supplier
    When I visit "/admin/suppliers"
    When I delete a supplier
    Then I see a list of suppliers
    And I don't see the deleted supplier
