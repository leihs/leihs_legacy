Feature: Inventory (CSV export)

  Background:
    Given personas dump is loaded

  @leihs_admin_inventory_csv
  Scenario: Export of the entire inventory to a CSV file
    Given I am Gino
    And I open the list of inventory pools
    When I click on the dropdown toggle for 'Export Inventory'
    Then I see 'Excel' option in the dropdown menu
    Then I see 'CSV' option in the dropdown menu
