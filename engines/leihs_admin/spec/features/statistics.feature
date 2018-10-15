Feature: Statistics on lending and inventory

  Background:
    Given personas dump is loaded
    And I am Ramon

  @leihs_admin_statistics
  Scenario: Title of the statistics section
    Given I visit "/admin/statistics"
    Then the page title is 'Statistics'

  @leihs_admin_statistics
  Scenario: Filtering statistics by time window
    Given I visit "/admin/statistics"
    And I select the statistics subsection "Who borrowed the most things?"
    Then I see by default the last 30 days' statistics
    When I set the time frame to 1/1 - 31/12 of the current year

  @leihs_admin_statistics
  Scenario: Statistics on number of lends per model
    Given I visit "/admin/statistics"
    And I select the statistics subsection "Which inventory pool is busiest?"
    Then I see the busiest inventory pools
    When I expand an inventory pool
    Then I see all models which this inventory pool is responsible for
    And I see the number of lends for each model

  @leihs_admin_statistics
  Scenario: Statistics about users and their lendings
    Given I visit "/admin/statistics"
    And I select the statistics subsection "Who borrowed the most things?"
    Then I see users with most lends
    When I expand the first user
    Then I see all models which the users has borrowed
    And I see the number of lends for each model

  @leihs_admin_statistics
  Scenario: Statistics about the items' value
    Given I visit "/admin/statistics"
    And I select the statistics subsection "Who bought the most items?"
    Then I see inventory pools which bought the most items
    When I expand an inventory pool
    Then I see all models for which this inventory pool owns items
    And for each model a sum of the purchase price of all matching items in this inventory pool
    And for each model the number of items of this model in that inventory pool
