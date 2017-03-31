
Feature: Model properties

  Background:
    Given I am Mike

  Scenario: Creating properties
  Given I create a model and fill in all required fields
  When I add some properties and fill in their keys and values
  And I sort the properties
  And I save the model
  Then this model's properties are saved in the order they were given

  Scenario: Editing properties
  Given I am editing a model
  When I add some properties and fill in their keys and values
  And I change existing properties
  And I sort the properties
  And I save the model
  Then this model's properties are saved in the order they were given

  Scenario: Deleting properties
  Given I edit a model that already has properties
  When I delete one or more existing properties
  And I save the model
  Then the properties for the changed model are saved in the order they were given
