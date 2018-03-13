Feature: Inventory pools

  @borrow_inventory_pools
  Scenario: Check inventory pools list
    Given there exists a user
    And there is a pool A with borrowable items the user has access to
    And there is a pool B without borrowable items the user has access to
    And there is a pool C the user has access to but the user is suspended for
    And there is a pool D the user had access to in the past
    When I am logged in as the user
    And I visit the page of my inventory pools
    Then I see 3 pools
    And I see pool A
    And I see pool B with a label "Does not have any reservable items"
    And I see pool C with a label "You are suspended for this inventory pool"
