Feature: Global search within an inventory pool

  Background:
    Given personas dump is loaded

  # Search overview should display contracts matching the user, delegation or contact person of a delegation.
  # First signed contracts, then closed contracts should be displayed.
  # Signed contracts should be sorted: 1. normal user first then delegation, 2. user name ASC.
  # Closed contracts should be sorted according to created date DESC.
  @manage_global_search
  Scenario: Search overview should display contracts according to the defined sort order
    Given I am Pius
    And a signed contract 1 for a user matching 'search string' exists
    And a signed contract 2 for a second user matching 'xsearch string' exists
    And a signed contract 3 for a delegation matching 'search string' exists
    And a closed contract 4 for a user matching 'search string' created on "01.01.2017" exists
    And a closed contract 5 for a contact person of a delegation matching 'search string' created on "01.01.2016" exists
    When I search globally for 'search string'
    Then within the contracts box I see contracts sorted as follows:
      | contract 1 |
      | contract 2 |
      | contract 3 |
      | contract 4 |
      | contract 5 |

  @manage_global_search
  Scenario: Contracts tab should display contracts according to the defined sort order (as in search overview)
    Given I am Pius
    And a signed contract 1 for a user matching 'search string' exists
    And a signed contract 2 for a second user matching 'xsearch string' exists
    And a signed contract 3 for a delegation matching 'search string' exists
    And a closed contract 4 for a user matching 'search string' created on "01.01.2017" exists
    And a closed contract 5 for a contact person of a delegation matching 'search string' created on "01.01.2016" exists
    When I search globally for 'search string'
    And I wait until the contracts container is shown
    And I switch to the contracts tab
    Then I see contracts sorted as follows:
      | contract 1 |
      | contract 2 |
      | contract 3 |
      | contract 4 |
      | contract 5 |

  @manage_global_search
  Scenario: Searching for a retired item of an inactive pool
    Given I am Pius
    And there is a retired item
    And there is an inactive inventory pool
    And the owner of the item is the inactive inventory pool
    And the responsible of the item is the inactive inventory pool
    When I search globally for the inventory code of the item
    Then I see within the items box the item
    And the item line contains the name of the inactive inventory pool
    And the item line has the label "Retired"
