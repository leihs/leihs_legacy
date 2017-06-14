Feature: Inventory search

  Background:
    Given personas dump is loaded

  @manage_inventory_search
  Scenario: Search in inventory includes the room of items
    Given I am Mike
    And there is an item the current pool is owner of situated in room "RoomX"
    And there is an item the current pool is owner of situated in room "RoomY"
    When I open the inventory list page
    And I search after "RoomX"
    Then I see one model line corresponding to the item situated in "RoomX"

