Feature: User documents

  Scenario: Getting to my documents
    Given I am a customer with contracts
    When I click on "My Documents" underneath my username
    Then I am on the page showing my documents

  Scenario: Document overview
    Given I am a customer with contracts with different dates
    And I go to the page showing my documents
    Then my contracts are ordered by the earliest time window
    And I see the following information for each contract:
      | Contract number                    |
      | Time window with its start and end |
      | Inventory pool                     |
      | Purpose                            |
      | Status                             |
      | Link to the contract               |
      | Link to the value list             |

  Scenario: Person taking back
    Given I am a customer with contracts
    When I open a contract with returned items from my documents
    Then the relevant reservations show the person taking back the item in the format "F. Lastname"

  Scenario: Opening value list
    Given I am a customer with contracts
    And I go to the page showing my documents
    And I click the value list link
    Then the value list opens

  Scenario: What I want to see on a value list
    Given I am a customer with contracts
    When I open a value list from my documents
    Then I want to see the following sections in the value list:
      | Section  |
      | Date     |
      | Title    |
      | Borrower |
      | Lender   |
      | List     |
    And the models in the value list are sorted alphabetically
    Then the list contains the following columns:
      | Column             |
      | Consecutive number |
      | Inventory code     |
      | Model name         |
      | End date           |
      | Quantity           |
      | Price              |
    Then one line shows the grand total
    And that shows the totals of the columns:
      | Column   |
      | Quantity |
      | Value    |

  @flapping
  Scenario: Opening a contract
    Given I am a customer with contracts
    And I go to the page showing my documents
    And I click the contract link
    Then the contract opens

  Scenario: What I want to see on the contract
    Given I am a customer with contracts
    When I open a contract from my documents
    Then I see the contract and it looks like in the manage section
