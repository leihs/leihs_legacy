Feature: Category CRUD

  Background:
    Given personas dump is loaded

  @manage_category_crud
  Scenario: Adding, changing and removing an image
    Given I am Mike
    And there is a category without image
    When I open the edit page of the category
    And I add an image
    And I save
    Then the category has been saved successfully
    When I open the edit page of the category
    Then the category has the chosen image
    When I remove the image
    And I add another image
    And I save
    Then the category has been saved successfully
    When I open the edit page of the category
    Then the category has the chosen image
    When I remove the image
    And I save
    Then the category has been saved successfully
    When I open the edit page of the category
    Then the category does not have any image
