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
    And I choose a building
    And I choose a room
    And I enter serial number "abcd"
    And I save and cancel the confirmation dialog
    Then I stay on the create item page
    And the loading icon was hidden
    And the new item was not created

  @manage_serial_number_validation @broken
  Scenario: Accepting the confirmation dialog on create item page
    Given I am Mike
    And there is an item with serial number "abcd"
    When I open the page for creating a new item
    And I enter an inventory code
    And I select a model
    And I choose a building
    And I choose a room
    And I enter serial number "aB Cd"
    And I save
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
    And I save and cancel the confirmation dialog
    Then I stay on the edit item page
    And the loading icon was hidden
    And the item was not updated

  @manage_serial_number_validation @broken
  Scenario: Accepting the confirmation dialog on edit item page
    Given I am Mike
    And there is an item with serial number "abcd"
    And there is another item in the current inventory pool
    When I open the page for editing an item
    And I enter serial number "aB Cd"
    And I save
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

  # @manage_serial_number_validation
  # Scenario: Skip serial number validation automatically for items when creating a package
  #   Given I am Mike
  #   And there is first item with serial number "abcd"
  #   And there is second item with serial number "abcd"
  #   And there is a package model
  #   When I open edit page of the model
  #   And I click on "Add Package"
  #   And I add the first item
  #   And I add the second item
  #   And I choose the general building
  #   And I choose the general room
  #   And I click on "Save Package"
  #   And I click on "Save Model"
  #   Then I see a success message
  #   And the package was created successfully and contains both the items
