Feature: Audits

  Background:
    Given personas dump is loaded
    And I am Gino

  @leihs_admin_audits
  Scenario: Listing audits
    When I navigate to the audits page
    When I visit "/admin/audits"
    Then I see the list of audits
