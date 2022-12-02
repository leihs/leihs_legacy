Feature: Inventory

  Background:
    Given personas dump is loaded

  @manage_inventory
  Scenario: Search in inventory includes the room of items
    Given I am Mike
    And there is an item the current pool is owner of situated in room "RoomX"
    And there is an item the current pool is owner of situated in room "RoomY"
    When I open the inventory list page
    And I search after "RoomX"
    Then I see one model line corresponding to the item situated in "RoomX"

  #########################################################################################
  # ISSUE: Background step is not defined when running as scenario outline, that's why
  # splitting into individual scenarios.
  #########################################################################################

  # @manage_inventory
  # Scenario Outline: Items are sorted by the inventory code
  #   Given I am Mike
  #   And there exists a <model type>
  #   And there are 3 <item type>s for the <model type> in the current inventory pool
  #   When I open the inventory list page
  #   And I search after the <model type>'s name
  #   And I see one line corresponding to the <model type>'s name
  #   And I open the dropdown for the <model type>
  #   Then the dropdown contains 3 <item type> lines
  #   And the <item type> lines are sorted alphabetically by their inventory code
  #   Examples:
  #     | model type | item type |
  #     | model      | item      |
  #     | software   | license   |

  @manage_inventory
  Scenario: Items are sorted by the inventory code
    Given I am Mike
    And there exists a model
    And there are 3 items for the model in the current inventory pool
    When I open the inventory list page
    And I search after the model's name
    And I see one line corresponding to the model's name
    And I open the dropdown for the model
    Then the dropdown contains 3 item lines
    And the item lines are sorted alphabetically by their inventory code

  @manage_inventory
  Scenario: Licenses are sorted by the inventory code
    Given I am Mike
    And there exists a software
    And there are 3 licenses for the software in the current inventory pool
    When I open the inventory list page
    And I search after the software's name
    And I see one line corresponding to the software's name
    And I open the dropdown for the software
    Then the dropdown contains 3 license lines
    And the license lines are sorted alphabetically by their inventory code

  #########################################################################################
  #########################################################################################
  #########################################################################################
