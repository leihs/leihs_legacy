Feature: Global search within an inventory pool

  Background:
    Given personas dump is loaded

  @manage_global_search
  Scenario: Search overview should display contracts matching the user, delegation or contact person of a delegation and sorted alphabetically
    Given I am Pius
    And a signed contract for a user matching 'search string' exists
    And a signed contract for a second user matching 'xsearch string' exists
    And a closed contract for a user matching 'search string' exists
    And a signed contract for a delegation matching 'search string' exists
    And a closed contract for a contact person of a delegation matching 'search string' exists
    When I search globally for 'search string'
    Then within the contracts box on the 1st position I see the signed contract for the user
    Then within the contracts box on the 2nd position I see the signed contract for the second user
    Then within the contracts box on the 3rd position I see the closed contract for the user
    And within the contracts box on the 4th position I see the signed contract for the delegation
    And within the contracts box on the 5th position I see the closed contract for the contact person of a delegation

  @manage_global_search
  Scenario: Contracts tab should display contracts matching the user, delegation or contact person of a delegation and sorted alphabetically
    Given I am Pius
    And a signed contract for a user matching 'search string' exists
    And a signed contract for a second user matching 'xsearch string' exists
    And a closed contract for a user matching 'search string' exists
    And a signed contract for a delegation matching 'search string' exists
    And a closed contract for a contact person of a delegation matching 'search string' exists
    And a closed contract for a second delegation matching 'xsearch string' exists
    When I search globally for 'search string'
    And I switch to the contracts tab
    Then on the 1st position I see the signed contract for the user
    Then on the 2nd position I see the signed contract for the second user
    Then on the 3rd position I see the closed contract for the user
    And on the 4th position I see the signed contract for the delegation
    And on the 5th position I see the closed contract for the contact person of a delegation
    And on the 6th position I see the closed contract for the second delegation

