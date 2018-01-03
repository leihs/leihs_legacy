
Feature: Inventory pools

  @rack
  Scenario: Check inventory pools list
    Then I see the inventory pools which have borrowable items or a contract for my user exists
