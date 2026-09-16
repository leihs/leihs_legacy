Feature: Pickup location lending UI

  Background:
    Given personas dump is loaded

  @manage_pickup_location_lending
  Scenario: Courier UI is hidden when alternative pickup locations are disabled
    Given I am Pius
    And a customer for my inventory pool exists
    And an item owned by my inventory pool exists
    And the customer has an approved reservation for the item with an alternative pickup location
    When I open hand over for the user
    Then the pickup location is not shown on the hand over line
    And the handed to courier checkbox is not shown on the hand over line

  @manage_pickup_location_lending
  Scenario: Hand-over shows pickup location and courier checkbox when feature enabled
    Given I am Pius
    And the current pool has alternative pickup locations enabled
    And a customer for my inventory pool exists
    And an item owned by my inventory pool exists
    And the customer has an approved reservation for the item with an alternative pickup location
    When I open hand over for the user
    Then the pickup location is shown on the hand over line
    And the handed to courier checkbox is shown on the hand over line
    And the pickup location and courier checkbox are fully visible on the hand over line
    When I check the handed to courier checkbox on the hand over line
    Then the reservation is marked as sent to the pickup location
    And the reservation is still approved without a contract

  @manage_pickup_location_lending
  Scenario: Take-back shows courier checkbox when feature enabled
    Given I am Pius
    And the current pool has alternative pickup locations enabled
    And a customer for my inventory pool exists
    And an item owned by my inventory pool exists
    And the customer has borrowed the item for today with an alternative pickup location
    When I open take back for the user
    Then the handed to courier checkbox is shown on the take back line
    When I check the handed to courier checkbox on the take back line
    Then the reservation is marked as sent back to the main location
    And the reservation is still signed and not returned

  @manage_pickup_location_lending
  Scenario: Checking handed to courier on one selected line does not change the other
    Given I am Pius
    And the current pool has alternative pickup locations enabled
    And a customer for my inventory pool exists
    And two items owned by my inventory pool exist
    And the customer has borrowed both items for today with an alternative pickup location
    When I open take back for the user
    And I select both take back lines
    And I check the handed to courier checkbox on the first take back line
    Then only the first reservation is marked as sent back to the main location
    And both reservations are still signed and not returned

  @manage_pickup_location_lending
  Scenario: Group courier select-all checks all courier checkboxes in that group
    Given I am Pius
    And the current pool has alternative pickup locations enabled
    And a customer for my inventory pool exists
    And two items owned by my inventory pool exist
    And the customer has borrowed both items for today with an alternative pickup location
    When I open take back for the user
    And I check the courier select-all checkbox for the group
    Then both reservations are marked as sent back to the main location
    And both reservations are still signed and not returned

  @manage_pickup_location_lending
  Scenario: Courier select-all is shown only for groups with courier checkboxes
    Given I am Pius
    And the current pool has alternative pickup locations enabled
    And a customer for my inventory pool exists
    And two items owned by my inventory pool exist
    And the customer has an approved reservation for the first item with an alternative pickup location
    And the customer has an approved reservation for the second item without a pickup location starting later
    When I open hand over for the user
    Then the courier select-all checkbox is shown for the group with the pickup location
    And the courier select-all checkbox is not shown for the group without a pickup location

  @manage_pickup_location_lending
  Scenario: Edit reservation shows pickup location under the model when feature enabled
    Given I am Pius
    And the current pool has alternative pickup locations enabled
    And a customer for my inventory pool exists
    And an item owned by my inventory pool exists
    And the customer has an approved reservation for the item with an alternative pickup location
    When I open hand over for the user
    And I open the edit reservation dialog for the line
    Then the pickup location is shown under the model in the edit reservation dialog

  @manage_pickup_location_lending
  Scenario: Edit reservation hides pickup location when feature is disabled
    Given I am Pius
    And a customer for my inventory pool exists
    And an item owned by my inventory pool exists
    And the customer has an approved reservation for the item with an alternative pickup location
    When I open hand over for the user
    And I open the edit reservation dialog for the line
    Then the pickup location is not shown in the edit reservation dialog

  @manage_pickup_location_lending
  Scenario: Edit reservation hides pickup location for main warehouse
    Given I am Pius
    And the current pool has alternative pickup locations enabled
    And a customer for my inventory pool exists
    And an item owned by my inventory pool exists
    And the customer has an approved reservation for the item without an alternative pickup location
    When I open hand over for the user
    And I open the edit reservation dialog for the line
    Then the pickup location is not shown in the edit reservation dialog

  @manage_pickup_location_lending
  Scenario: Take-back hides courier checkbox for main warehouse
    Given I am Pius
    And the current pool has alternative pickup locations enabled
    And a customer for my inventory pool exists
    And an item owned by my inventory pool exists
    And the customer has borrowed the item for today
    When I open take back for the user
    Then the handed to courier checkbox is not shown on the take back line

  @manage_pickup_location_lending
  Scenario: Take-back hides courier checkbox for a non-transportable model
    Given I am Pius
    And the current pool has alternative pickup locations enabled
    And a customer for my inventory pool exists
    And an item owned by my inventory pool exists
    And the item model is not transportable
    And the customer has borrowed the item for today with an alternative pickup location
    When I open take back for the user
    Then the handed to courier checkbox is not shown on the take back line
    And the pickup location is not shown on the take back line

  @manage_pickup_location_lending
  Scenario: Take-back courier checkbox is shown only for transportable pickup-location lines
    Given I am Pius
    And the current pool has alternative pickup locations enabled
    And a customer for my inventory pool exists
    And two items owned by my inventory pool exist
    And the first item model is not transportable
    And the customer has borrowed both items for today, the second with an alternative pickup location
    When I open take back for the user
    Then the handed to courier checkbox is shown only on the take back line for the second item
    And the courier select-all checkbox is shown on the take back group

  @manage_pickup_location_lending
  Scenario: Hand-over list and Edit Selection show pickup and courier only for transportable models
    Given I am Pius
    And the current pool has alternative pickup locations enabled
    And a customer for my inventory pool exists
    And two items owned by my inventory pool exist
    And the first item model is not transportable
    And the customer has approved reservations for both items with an alternative pickup location
    And the second item model has three non-adjacent unavailable periods within the reservation range
    When I open hand over for the user
    Then the pickup location and handed to courier are shown only on the hand over line for the second item
    When I select both hand over lines
    And I open Edit Selection
    Then the pickup location is shown only for the transportable model in the edit reservation dialog
    And three unavailable date ranges are shown for the transportable model in the edit reservation dialog

