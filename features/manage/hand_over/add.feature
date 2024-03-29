Feature: Add reservations during hand over

  In order to hand things over and add reservations to the contract
  As a lending manager
  I want to be able to have functionlities to add reservations

  Background:
    Given I am Pius

  Scenario: Add an item to the hand over providing an inventory code
    Given I open a hand over
    When I add a borrowable item to the hand over by providing an inventory code
    Then the item is added to the hand over for the provided date range and the inventory code is already assigend
    When I add an unborrowable item to the hand over by providing an inventory code
    Then the item is added to the hand over for the provided date range and the inventory code is already assigend

  Scenario: Add an option to the hand over providing an inventory code
    Given I open a hand over
    And I add an option to the hand over by providing an inventory code
    Then the option is added to the hand over

  Scenario: Increase the quantity of an option of the hand over by adding an option providing an inventory code
    Given I open a hand over with options
    When I add an option to the hand over by providing an inventory code
    Then the quantity on the option line is 1
    And I add an option to the hand over by providing an inventory code
    Then the quantity on the option line is 2

  Scenario: Add a template to the hand over picking an autocomplete element
    Given I open a hand over
    And I type the beginning of a template name to the add/assign input field
    Then I see a list of suggested template names
    When I select the template from the list
    Then each model of the template is added to the hand over for the provided date range

  @unstable
  Scenario: Add reservations which changes other reservations availability
    Given I open a hand over for today
    And I add so many reservations that I break the maximal quantity of a model
    Then I see that all reservations of that model have availability problems

  Scenario: Add an option to the hand over picking an autocomplete element
    Given I open a hand over
    And I type the beginning of an option name to the add/assign input field
    Then I see a list of suggested option names
    When I select the option from the list
    Then the option is added to the hand over

  Scenario: Add an model to the hand over picking an autocomplete element
    Given I open a hand over
    And I type the beginning of a model name to the add/assign input field
    Then I see a list of suggested model names
    When I select the model from the list
    Then the model is added to the hand over

  Scenario: hand over items even if not borrowable
    Given I open a hand over
    And there is a model or software which all items are set to "not borrowable"
    When I type the beginning of that model name to the add/assign input field
    Then I see a list of suggested model names
    And I see that model in the list of suggested model names as "not borrowable"
    When I select the model from the list
    Then the model is added to the hand over

  Scenario: Add a line to the hand over providing a model name
    Given I open a hand over
    When I enter a model name which is not related to my current pool
    Then only models related to my current pool are suggested

  Scenario: Adding a retired item should not be possible
    Given I open a hand over
    When I add a retired item to the hand over by providing an inventory code
    Then I see the error message "The item is already retired"
    And I don't see the inventory code on the page
