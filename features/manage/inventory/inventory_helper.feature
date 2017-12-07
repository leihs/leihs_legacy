
Feature: Inventory helper

  Background:
    Given I am Matti

  @rack
  Scenario: Wie man den Helferschirm erreicht
    When I open the inventory
    Then I see a tab where I can change to the inventory helper

  Scenario: You can't change the responsible department while something is not in stock
    Given I go to the inventory helper screen
    And I edit the field "Responsible department" of an item that isn't in stock and belongs to the current inventory pool
    Then I see an error message that I can't change the responsible inventory pool for items that are not in stock

  Scenario: You can't retire something that is not in stock
    Given I go to the inventory helper screen
    And I retire an item that is not in stock
    Then I see an error message that I can't retire the item because it's already handed over or assigned to a contract

  Scenario: Editing items on the helper screen using a complete inventory code (barcode scanner)
    Given I go to the inventory helper screen
    When I choose all fields through a list or by name
    And I set all their initial values
    Then I scan or enter the inventory code of an item that is in stock and not in any contract
    Then I see all the values of the item in an overview with model name and the modified values are already saved
    And the changed values are highlighted

  Scenario: Required fields
    Given I go to the inventory helper screen
    When "Reference" is selected and set to "Investment", then "Project Number" must also be filled in
    When "Retirement" is selected and set to "Yes", then "Reason for Retirement" must also be filled in
    Then all required fields are marked with an asterisk
    When a required field is blank, the inventory helper cannot be used
    And I see an error message
    And the required fields are highlighted in red

  Scenario: Trying to edit an inexistant item through the inventory helper
    Given I go to the inventory helper screen
    And I choose the fields from a list or by name
    And I set their initial values
    Then I scan or enter the inventory code of an item that can't be found
    Then I see an error message

  Scenario: Using autocomplete to edit items on the inventory helper
    Given I go to the inventory helper screen
    And I choose the fields from a list or by name
    And I set their initial values
    Then I start entering an item's inventory code
    And I choose the item from the list of results
    Then I see all the values of the item in an overview with model name and the modified values are already saved
    And the changed values are highlighted

  Scenario: Editing after automatic save
    Given I edit an item through the inventory helper using an inventory code
    When I use the edit feature
    Then I can edit all of this item's values right then and there
    When I save
    Then my changes are saved

  Scenario: Canceling an edit after automatic save
    Given I edit an item through the inventory helper using an inventory code
    When I use the edit feature
    Then I can edit all of this item's values right then and there
    When I cancel
    Then the changes are reverted
    And I see all the values of the item in an overview with model name and the modified values are already saved

  Scenario: You can't edit certain fields for items that are in contracts
    Given I go to the inventory helper screen
    And I edit the field "Model" of an item that is part of a contract
    Then I see an error message that I can't change the model because the item is already handed over or assigned to a contract
