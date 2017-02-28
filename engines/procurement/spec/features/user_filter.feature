Feature: User's filter

  @user_filter
  Scenario: User's filter is deleted together with procurement access
    Given I am Hans Ueli
    And I am also a requester
    And I have a user filter set
    When my requester access is deleted
    Then my user filter still exists
    When my admin access is deleted
    Then my user filter is deleted too

  @user_filter
  Scenario: User's filter is deleted together with user
    Given there is a user with filter
    When the user is deleted
    Then the filter is deleted too
