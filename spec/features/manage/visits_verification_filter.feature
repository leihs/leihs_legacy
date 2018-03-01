Feature: Visits verification filter

  Background:
    Given there is an inventory pool
    And there is a lending manager in this inventory pool
    And there is an entitlement group with required verification
    And there is a hand over 1 without required verification
    And there is a hand over 2 with user to verify
    And there is a hand over 3 with user and model to verify
    And there is a take back 1 without required verification
    And there is a take back 2 with user to verify
    And there is a take back 3 with user and model to verify
    And I am logged in as the lending manager
    And I open the visits page

  @manage_visits_verification_filter
  Scenario: Showing all visits
    Then I see 6 visits
    And I see hand over 1
    And I see hand over 2
    And I see hand over 3
    And I see take back 1
    And I see take back 2
    And I see take back 3

  @manage_visits_verification_filter
  Scenario: Showing visits without required verification
    Given I choose "No verification required" from the select field
    Then I see 2 visits
    And I see hand over 1
    And I see take back 1

  @manage_visits_verification_filter
  Scenario: Showing visits with user to be verified
    Given I choose "User to be verified" from the select field
    Then I see 4 visits
    And I see hand over 2
    And I see hand over 3
    And I see take back 2
    And I see take back 3

  @manage_visits_verification_filter
  Scenario: Showing visits with user and model to verify
    Given I choose "User and model to be verified" from the select field
    Then I see 2 visits
    And I see hand over 3
    And I see take back 3

  @manage_visits_verification_filter
  Scenario: Showing all hand overs
    Given I click on hand over tab
    And I choose "All" from the select field
    Then I see 3 visits
    And I see hand over 1
    And I see hand over 2
    And I see hand over 3

  @manage_visits_verification_filter
  Scenario: Showing hand overs without required verification
    Given I click on hand over tab
    And I choose "No verification required" from the select field
    Then I see 1 visits
    And I see hand over 1

  @manage_visits_verification_filter
  Scenario: Showing hand overs with user to be verified
    Given I click on hand over tab
    And I choose "User to be verified" from the select field
    Then I see 2 visits
    And I see hand over 2
    And I see hand over 3

  @manage_visits_verification_filter
  Scenario: Showing hand overs with user and model to verify
    Given I click on hand over tab
    And I choose "User and model to be verified" from the select field
    Then I see 1 visits
    And I see hand over 3

  @manage_visits_verification_filter
  Scenario: Showing all take backs
    Given I click on take back tab
    And I choose "All" from the select field
    Then I see 3 visits
    And I see take back 1
    And I see take back 2
    And I see take back 3

  @manage_visits_verification_filter
  Scenario: Showing take backs without required verification
    Given I click on take back tab
    And I choose "No verification required" from the select field
    Then I see 1 visits
    And I see take back 1

  @manage_visits_verification_filter
  Scenario: Showing take back with user to be verified
    Given I click on take back tab
    And I choose "User to be verified" from the select field
    Then I see 2 visits
    And I see take back 2
    And I see take back 3

  @manage_visits_verification_filter
  Scenario: Showing take backs with user and model to verify
    Given I click on take back tab
    And I choose "User and model to be verified" from the select field
    Then I see 1 visits
    And I see take back 3
