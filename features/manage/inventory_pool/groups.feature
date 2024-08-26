Feature: Entitlement Groups

  Background:
    Given I am Pius
    And I am in the admin area's groups section

  @rack
  Scenario: Anzeige der Gruppenliste
    When I am listing groups
    Then each group shows the number of users assigned to it
    And each group shows how many of each model are assigned to it

  Scenario: Visierungspflichtige Gruppe erstellen
    When I create a group
    And I select 'Verification required'
    And I fill in the group's name
    # And I add users to the group
    And I add models and capacities to the group
    And I save
    Then the group is saved
    And the group requires verification
    And the group has models and their capacities

  Scenario: Mark a group as requiring verification
    When I edit an existing non verifiable group
    And I select 'Verification required'
    And I change the group's name
    And I add and remove models and their capacities from the group
    And I save
    Then the group is saved
    And the group requires verification
    And the group has models and their capacities
    Then I am listing groups
    And I receive a notification of success

  Scenario: Group does not require verification
    When I edit an existing verifiable group
    And I deselect 'Verification required'
    And I change the group's name
    And I add and remove models and their capacities from the group
    And I save
    Then the group is saved
    And the group doesn't require verification
    And the group has models and their capacities
    Then I am listing groups
    And I receive a notification of success

  Scenario: Capacities still available for assignment
    When I create a group
    # And I add users to the group
    And I add models and capacities to the group
    Then I see any capacities that are still available for assignment

  Scenario: Deleting groups
    When I delete a group
    And the group has been deleted from the database

  Scenario: Adding models
    When I edit an existing group
    And I add a model to the group
    Then the model is added to the top of the list

  @rack
  Scenario: Sorting models
    When I edit an existing group
    Then the already present models are sorted alphabetically

  Scenario: Adding already existing models
    When I edit an existing group
    And I add a model that is already present in the group
    Then the model is not added again
    And the already existing model slides to the top of the list
    And the already existing model keeps whatever capacity was set for it

  @rack
  Scenario: Sorting the group list
    When I am listing groups
    Then the list is sorted alphabetically

  Scenario: Creating a group
    When I create a group
    And I fill in the group's name
    # And I add users to the group
    And I add models and capacities to the group
    And I save
    Then the group is saved
    And I receive a notification of success
    And the group has models and their capacities
    When I am listing groups
