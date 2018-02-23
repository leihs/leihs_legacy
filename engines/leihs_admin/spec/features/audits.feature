Feature: Audits

  Background:
    Given personas dump is loaded
    And I am Gino

  @leihs_admin_audits
  Scenario: Listing audits
    When I navigate to the audits page
    When I click on the "Audits" navigation tab
    Then I see the list of audits

  @leihs_admin_audits
  Scenario: Searching in audits
    Given there is a user whose name contains "termXYZ"
    And there is an item whose inventory code contains "termXYZ"
    And there is a 'create' audit which contains "termXYZ" in column 'audited_changes'
    And there is a 'create' audit for a user whose name contains "termXYZ"
    And there is a 'create' audit performed by a user whose name contains "termXYZ"
    And there is a 'create' audit for an item whose inventory code contains "termXYZ"
    And there is an 'update' audit for an item whose inventory code contains "termXYZ"
    And there is a 'create' audit for a model whose name contains "termXYZ"
    When I navigate to the audits page
    And I enter "termXYZ" in the search input field
    And click on "Filter"
    And I scroll down until I see all audits
    Then I see 6 audits

  @leihs_admin_audits
  Scenario: Display of inventory code for audit of an item
    Given there exists a new audit for an item
    When I navigate to the audits page
    Then I see the inventory code of the item on its audit entry

  @leihs_admin_audits
  Scenario: Display of model name for audit of a model
    Given there exists a new audit for a model
    When I navigate to the audits page
    Then I see the model name of the model on its audit entry

  @leihs_admin_audits
  Scenario: Display of user name for audit of a user
    Given there exists a new audit for a user
    When I navigate to the audits page
    Then I see the user name of the user on its audit entry

  @leihs_admin_audits
  Scenario: Default time range and sorting
    Given there exists a new audit
    When I navigate to the audits page
    Then the end date is set to today
    And the start date is set to one month ago
    And I see the request with the new audit at the top

  @leihs_admin_audits
  Scenario: Individual audits page for particular entity
    Given there is an item whose inventory code contains "termXYZ"
    And there is a 'create' audit for an item whose inventory code contains "termXYZ"
    And I navigate to the audits page
    And the end date is set to today
    And the start date is set to one month ago
    And I enter "termXYZ" in the search input field
    And click on "Filter"
    And I scroll down until I see all audits
    Then I see 1 audit for the item
    When I click on the label link of the item
    Then an individual audits page opens for the audits of this item
    Then I see 1 audit for the item
    And the end date is set to today
    And the start date is set to one month ago
    And the search input field contains "termXYZ"
