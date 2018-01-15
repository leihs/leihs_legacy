
Feature: Model

  Background:
    Given I am Mike
    And I open the inventory

  Scenario: Overview when adding a new model
    When I add a new Model
    Then I can enter the following information:
      | Details |
      | Images  |
      | Attachments |
      | Accessories |

  Scenario: Filling in model details
    When I add a new Model
    And I enter the following details
      | Field                         | Value                     |
      | Product                       | Test model                |
      | Manufacturer                  | Test manufacturer         |
      | Description                   | Test description          |
      | Technical Details             | Test technical details    |
      | Internal Description          | Test internal description |
      | Important notes for hand over | Test notes                |
    And I save
    Then the new model is created and can be found in the list of unused models

  Scenario: Editing model accessories
    When I edit a model that exists, is in use and already has activated accessories
    Then I see all the accessories for this model
    And I see which accessories are active for my pool
    When I add accessories and, if necessary, fill in the quantity in the text field
    And I save
    Then accessories are added to the model

  Scenario: Deleting model accessories
    When I edit a model that exists, is in use and already has accessories
    Then I can delete a single accessory if it is not active in any other pool

  Scenario: Deactivating model accessories
    When I edit a model that exists, is in use and already has activated accessories
    Then I can deactivate an accessory for my pool

  Scenario: Remove compatible models
    When I open a model that already has compatible models
    And I remove a compatible model
    And I save
    Then the model is saved without the compatible model that I removed

  Scenario: Editing group capacities
    Given I edit a model that exists and has group capacities allocated to it
    When I remove existing allocations
    And I add new allocations
    And I save
    Then the changed allocations are saved

  Scenario: Delete model
    Given there is a model with the following conditions:
      | not in any contract |
      | not in any order|
      | no items assigned|
    When I delete this model from the list
    Then the model was deleted from the list
    And the model is deleted

  Scenario: Add compatible models
    When I edit a model that exists and is in use
    And I use the autocomplete field to add a compatible model
    And I save
    Then a compatible model has been added to the model I am editing

  Scenario: Adding a compatible model twice in a row
    When I open a model that already has compatible models
    And I add an already existing compatible model using the autocomplete field
    Then the redundant model was not added
    When I save
    Then the redundant compatible model was not added to this one

  Scenario: Delete model associations
    Given there is a model with the following conditions:
      | not in any contract       |
      | not in any order          |
      | no items assigned         |
      | has group capacities      |
      | has properties            |
      | has accessories           |
      | has images                |
      | has attachments           |
      | is assigned to categories |
      | has compatible models     |
    When I delete this model from the list
    Then the model is deleted
    And all associations have been deleted as well

  Scenario: Editing model details
    When I edit a model that exists and is in use
    And I edit the following details
      | Field                         | Value                       |
      | Product                       | Test Modell x               |
      | Manufacturer                  | Test Hersteller x           |
      | Description                   | Test Beschreibung x         |
      | Technical Details             | Test Technische Details x   |
      | Internal Description          | Test Interne Beschreibung x |
      | Important notes for hand over | Test Notizen x              |
    And I save
    Then the information is saved
    And the data has been updated

  Scenario Outline: Add Models and Software including attachments
    Given I add a <object> to the inventory
    When I enter the product name "Test Thingie With Attachment"
      And I add one or more attachments
      And I can also remove attachments again
      And I save
    Then the attachments are saved
  Examples:
    | object   |
    | model    |
    | software |

  Scenario Outline: Preventing deletion of a model
    Given the model has an assigned <assignment>
    Then I cannot delete the model from the list
  Examples:
    | assignment |
    | contract   |
    | order      |
    | item       |

  Scenario: Create a model with only a name
    When I add a new Model
    And I save
    Then the model is not saved because it does not have a name
    And I see an error message
    When I enter the name of an existing model
    And I save
    Then the model is not saved because it does not have a unique name
    And I see an error message
    When I edit the following details
      | Field   | Value         |
      | Product | Test Modell y |
    And I save
    Then the new model is created and can be found in the list of unused models

  Scenario: Images
    When I edit a model that exists and is in use
    And I add multiple images
    Then I can also remove those images
    When I save the model and its images
    Then the remaining images are saved for that model
    And the images are resized to their thumbnail size when I see them in lists
