Feature: Model CRUD

  Background:
    Given personas dump is loaded

  @manage_model_crud
  Scenario: Adding, changing and removing an image
    Given I am Mike
    And there is a model without image
    When I open the edit page of the model
    And I add an image
    And I save
    Then the model has been saved successfully
    When I open the edit page of the model
    Then the model has the chosen image
    When I remove the image
    And I add another image
    And I save
    Then the model has been saved successfully
    When I open the edit page of the model
    Then the model has the chosen image
    When I remove the image
    And I save
    Then the model has been saved successfully
    When I open the edit page of the model
    Then the model does not have any image
