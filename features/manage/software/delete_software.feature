
Feature: Deleting software

  Background:
    Given I am Mike

  Scenario: Deleting a software product
    Given there is a software with the following conditions:
      | not in any contract |
      | not in any order    |
      | has no licenses     |
    When I delete this software from the list
    Then the software was deleted from the list
    And the software is deleted

  Scenario: Deleting associated records when deleting software
    Given there is a software with the following conditions:
      | not in any contract |
      | not in any order    |
      | has no licenses     |
      | has attachments     |
    When I delete this software from the list
    And the software is deleted
    And all associations have been deleted as well

