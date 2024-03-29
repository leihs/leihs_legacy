
Feature: Contract

  Background:
    Given I am Pius

  Scenario: What I want to see on the contract
    Given I open a contract during hand over
    # And I pry
    Then I want to see the following areas:
    | Area                 |
    | Date                 |
    | Title                |
    | Borrower             |
    | Lender               |
    | List 1               |
    | List 2               |
    | List of purposes     |
    | Additional notes     |
    | Terms                |
    | Borrower's signature |
    | Page number          |
    | Barcode              |
    | Contract number      |
    And the models are sorted alphabetically within their group

  Scenario: Mentioning terms and conditions
    Given I open a contract during hand over
    Then I see a note mentioning the terms and conditions

  Scenario: User information on the contract
    Given I open a contract during hand over
    Then the following user information is included on the contract:
    | Area          |
    | First name    |
    | Last name     |
    | Street        |
    | Street number |
    | Country code  |
    | Postal code   |
    | City          |

  Scenario: List of returned items
    Given I open a contract during hand over
    When there are returned items
    Then I see list 1 with the title "Returned Items"
    And this list contains borrowed and returned items

  Scenario: Purposes
    Given I open a contract during hand over
    Then I see a comma-separated list of purposes
     And each unique purpose is listed only once

  Scenario: Date
    Given I open a contract during hand over
    Then I see today's date in the top right corner

  Scenario: Title
    Given I open a contract during hand over
    Then I see a title in the format "Contract No. #"

  Scenario: Position of the barcode
    Given I open a contract during hand over
    Then I see the barcode in the top left

  Scenario: Position of the borrower
    Given I open a contract during hand over
    Then I see the borrower in the top left corner

  Scenario: Content of lists 1 and 2
    Given I open a contract during hand over that contains software
    Then list 1 and list 2 contain the following columns:
    | Column name   |
    | Quantity        |
    | Inventory code  |
    | Model name    |
    | End date      |
    | Return date |
    When the contract contains a software license
    Then I additionally see the following information
    | Serial number  |

  @flapping
  Scenario: Rücknehmende Person
    Given I open a take back
    And I select all reservations of an open contract via Barcode
    And I click take back
    And I click take back inside the dialog
    Then the relevant reservations show the person taking back the item in the format "F. Lastname"

  Scenario: Lender
    Given I open a contract during hand over
    Then the lender is shown next to the borrower

  Scenario: List of borrowed items
    Given I open a contract during hand over
    When there are unreturned items
    Then I see list 2 with the title "Borrowed Items"
    And this list contains items that were borrowed but not yet returned

  Scenario: Listing the lending party's address
    Given I open a contract during hand over
    Then the inventory pool is listed as lender
    When the instance's address is configured in the global settings
    Then the lender address is shown underneath the lender

  @rack
  Scenario: Not showing a ", " after a user's address
    Given there is a contract for a user whose address ends with ", "
    When I open this user's contract
    Then their address is shown without the ", "
