Feature: Serial number validation

  Background:
    Given personas dump is loaded

  @manage_serial_number_validation
  Scenario: Canceling the confirmation dialog on create item page
    Given I am Mike
    And there is an item with serial number "aB Cd"
    When I open the page for creating a new item
    And I enter an inventory code
    And I select a model
    And I select a supply category
    And I choose a building
    And I choose a room
    And I enter serial number "abcd"
    And I save
    Then I see a confirmation dialog that there already exists same or similar serial number
    When I cancel the confirmation dialog
    Then I stay on the create item page
    And the loading icon was hidden
    And the new item was not created

  @manage_serial_number_validation
  Scenario: Accepting the confirmation dialog on create item page
    Given I am Mike
    And there is an item with serial number "abcd"
    When I open the page for creating a new item
    And I enter an inventory code
    And I select a model
    And I select a supply category
    And I choose a building
    And I choose a room
    And I enter serial number "aB Cd"
    And I save
    Then I see a confirmation dialog that there already exists same or similar serial number
    When I accept the confirmation dialog
    Then I was redirected to the inventory page
    And I see a success message
    And the new item was created

  @manage_serial_number_validation
  Scenario: Canceling the confirmation dialog on edit item page
    Given I am Mike
    And there is an item with serial number "aB Cd"
    And there is another item in the current inventory pool
    When I open the page for editing an item
    And I enter serial number "abcd"
    And I save
    Then I see a confirmation dialog that there already exists same or similar serial number
    When I cancel the confirmation dialog
    Then I stay on the edit item page
    And the loading icon was hidden
    And the item was not updated

  @manage_serial_number_validation
  Scenario: Accepting the confirmation dialog on edit item page
    Given I am Mike
    And there is an item with serial number "abcd"
    And there is another item in the current inventory pool
    When I open the page for editing an item
    And I enter serial number "aB Cd"
    And I save
    Then I see a confirmation dialog that there already exists same or similar serial number
    When I accept the confirmation dialog
    Then I was redirected to the inventory page
    And I see a success message
    And the item was updated

  @manage_serial_number_validation
  Scenario: Displaying warning message on inventory helper page
    Given I am Mike
    And there is an item with serial number "abcd"
    And there is an item with serial number "ABCD"
    When I open the inventory helper page
    And I choose "Shelf" from the field select box
    And I enter some shelf name in the shelf input field
    And I apply the values on item with serial number "ABCD"
    Then I see a warning in regards to existing serial number
    And the values were successfully applied to the item with serial number "ABCD"
