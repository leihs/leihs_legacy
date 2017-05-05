Feature: Authentication Systems

  Background:
    Given personas dump is loaded
    And I am Gino
    When I visit "/admin/authentication_systems"

  @leihs_admin_authentication_systems
  Scenario: Listing existing authentication systems
    Then I see a list of authentication systems
