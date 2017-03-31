
Feature: Model list

  @rack
  Scenario: Model list overview
    Given I am Normin
    When I am listing models
    Then I see the explorative search
    And I see the models of the selected category
    And I see the sort options
    And I see the inventory pool selector
    And I see filters for start and end date

  @rack
  Scenario: A single model list entry
    Given I am Normin
    When I am listing models
    And a single model list entry contains:
    | Image            |
    | Model name       |
    | Manufacturer     |
    | Selection button |

  @flapping
  Scenario: Scrolling the model list
    Given I am Normin
    And I see a model list that can be scrolled
    When I scroll to the end of the currently loaded list
    Then the next block of models is loaded and shown
    When I scroll to the end of the list
    Then all models of the chosen category have been loaded and shown

  Scenario: Sorting the model list
    Given I am Normin
    And I am listing models
    When I sort the list by "Model, ascending"
    Then the list is sorted by "Model", "ascending"
    When I sort the list by "Model, descending"
    Then the list is sorted by "Model", "descending"
    When I sort the list by "Manufacturer, ascending"
    Then the list is sorted by "Manufacturer", "ascending"
    When I sort the list by "Manufacturer, descending"
    Then the list is sorted by "Manufacturer", "descending"

  @rack
  Scenario: Standard settings for lending period
    Given I am Normin
    And I am listing models
    Then no lending period is set

  Scenario: Inventory pool selection cannot be empty
    Given I am Normin
    When I am listing models
    Then I cannot deselect all the inventory pools in the inventory pool selector

  @rack
  Scenario: Sorting the inventory pool selection
    Given I am Normin
    When I am listing models
    Then the inventory pool selection is ordered alphabetically

  Scenario: Inventory pool selection "select all"
    Given I am Normin
    When I am listing models
    And I select a specific inventory pool from the choices offered
    And I select all inventory pools using the "All inventory pools" function
    Then all inventory pools are selected
    And the inventory pool selector is still expanded
    And the model list contains models from all inventory pools

  Scenario: Inventory pool selection can never be empty
    Given I am Normin
    When I am listing models
    Then I cannot deselect all the inventory pools in the inventory pool selector

  Scenario: Specifying the start date of an order
    Given I am Petra
    When I am listing models and some of them are unavailable
    And I choose a start date
    Then the end date is automatically set to the next day
    And the list is filtered by models that are available in that time frame

  Scenario: Specifying the end date of an order
    Given I am Petra
    When I am listing models and some of them are unavailable
    And I choose an end date
    Then the start date is automatically set to the previous day
    And the list is filtered by models that are available in that time frame

  Scenario: Removing the lending time frame
    Given I am Petra
    When I am listing models and some of them are unavailable
    And I choose a start date
    And I choose an end date
    When I blank the start and end date
    Then the list is not filtered by lending time frame

  Scenario: Date picker for lending time frame
    Given I am Normin
    And I am listing models
    Then I can also use a date picker to specify start and end date instead of entering them by hand

  Scenario: Searching for a model
    Given I am Normin
    And I am listing models
    When I enter a search term
    And I press the Enter key
    Then those models are shown whose names or manufacturers match the search term

  Scenario: Hovering over models
    Given I am Normin
    And there is a model with images, description and properties
    And the model list contains that model
    When I hover over that model
    Then I see the model's name, images, description, list of properties
    When I open the calendar for this model
    And I hover over that model
    Then I see the model's name, images, description, list of properties

  @rack
  Scenario: Default values for inventory pool selection
    Given I am Normin
    When I am listing models
    Then all inventory pools are selected
    And the model list shows models from all inventory pools
    And the filter is labeled "All inventory pools"

  Scenario: Selecting just one inventory pool
    Given I am Normin
    And I am listing models
    When I select a specific inventory pool from the choices offered
    Then all other inventory pools are deselected
    And the model list shows only models of this inventory pool
    And the inventory pool selector is still expanded
    And the filter shows the name of the selected inventory pool

  Scenario: Deselecting a single inventory pool
    Given I am Normin
    And I am listing models
    When I deselect some inventory pools
    Then the model list is filtered by the left over inventory pools
    And the inventory pool selector is still expanded
    And the filter shows the count of selected inventory pools

  @flapping
  Scenario: Deselecting all but one inventory pool
    Given I am Normin
    And I am listing models
    When I deselect all but one inventory pool
    Then the model list is filtered by the left over inventory pool
    And the inventory pool selector is still expanded
    And the filter shows the name of the inventory pool that is left

  # this one is very strange; fails locally always; passes on CI sometimes
  @flapping
  Scenario: Resetting everything
    Given I am Normin
    And I am listing models
    And filters are being applied
    And the button "Reset all filters" is visible
    When I reset all filters
    Then all inventory pools are selected again in the inventory pool filter
    And start and end date are both blank
    And the list is sorted by "Model", "ascending"
    And the search query field is blank
    And the model list is unfiltered
    And the button "Reset all filters" is not visible

  Scenario: Reset all button disappears automatically when filters were set to their default positions by hand
    Given I am Normin
    And I am listing models
    And filters are being applied
    And the button "Reset all filters" is visible
    When I set all filters to their default values by hand
    Then the button "Reset all filters" is not visible
