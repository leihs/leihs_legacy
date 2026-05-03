
Feature: Navigation

  @rack
  Scenario: Navigation für Gruppen-Verwalter
    Given I am Andi
    And I visit the lending section
    Then I can see the navigation bars
    And the navigation contains "Lending"
    And the navigation contains "Borrow"
    And the navigation contains "User"

  @rack
  Scenario: Navigation für Gruppen-Verwalter in Verleih-Bereich
    Given I am Andi
    And I visit the lending section
    Then I can see the navigation bars
    And I open the tab "Orders"
    And I open the tab "Contracts"

  Scenario: Aufklappen der Geraeteparkauswahl und Wechsel des Geraeteparks
    Given I am Mike
    When I hover over the navigation toggler
    Then I see all inventory pools for which I am a manager
    When I click on one of the inventory pools
    Then I switch to that inventory pool

  @rack
  Scenario Outline: New inventory button is visible for manager roles
    Given a "<role>" for inventory pool "Topbar Role Test Pool" is logged in as "<login>"
    When I visit the lending section
    Then I see the new inventory button

    Examples:
      | role              | login                |
      | lending_manager   | role_test_lending    |
      | inventory_manager | role_test_inventory  |
      | group_manager     | role_test_group      |

  @rack
  Scenario: New inventory button is not visible for client role
    Given a "customer" for inventory pool "Topbar Role Test Pool" is logged in as "role_test_client"
    When I visit the homepage
    Then I do not see the new inventory button
