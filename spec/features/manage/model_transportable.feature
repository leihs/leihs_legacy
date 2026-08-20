Feature: Model transportable

  Background:
    Given personas dump is loaded

  @manage_model_transportable
  Scenario: Transportable checkbox is hidden when alternative pickup locations are disabled
    Given I am Mike
    When I open the create model page
    Then the transportable checkbox is not visible
    Given there is a model
    When I open the edit page of the model
    Then the transportable checkbox is not visible

  @manage_model_transportable
  Scenario: Transportable checkbox is hidden when pool has locations but feature is disabled
    Given I am Mike
    And the current pool has a pickup location
    When I open the create model page
    Then the transportable checkbox is not visible
    Given there is a model
    When I open the edit page of the model
    Then the transportable checkbox is not visible

  @manage_model_transportable
  Scenario: Transportable checkbox is shown and persisted when alternative pickup locations are enabled
    Given I am Mike
    And the current pool has alternative pickup locations enabled
    When I open the create model page
    Then the transportable checkbox is visible
    And the transportable checkbox is checked
    When I uncheck the transportable checkbox
    And I fill in the product name
    And I save
    Then the model has been saved successfully
    And the created model is not transportable
    When I open the edit page of the created model
    Then the transportable checkbox is visible
    And the transportable checkbox is not checked
    When I check the transportable checkbox
    And I save
    Then the model has been saved successfully
    And the created model is transportable
