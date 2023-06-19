Feature: Editing an item

  Background:
    Given I am Matti

  Scenario: Order of the fields when editing an item
    Given I edit an item that belongs to the current inventory pool
    # TODO: Remove web_steps.rb
    When I select "Yes" from "item[retired]"
    When I choose "Investment"
    Then I see form fields in the following order:
      | field                      |
      | Inventory Code             |
      | Model                      |
      | - Status -                 |
      | Retirement                 |
      | Reason for Retirement      |
      | Working order              |
      | Completeness               |
      | Borrowable                 |
      | Status note                |
      | - Inventory -              |
      | Relevant for inventory     |
      | Owner                      |
      | Last Checked               |
      | Responsible department     |
      | Responsible person         |
      | User/Typical usage         |
      | - Move -                   |
      | Move                       |
      | Target area                |
      | - General Information -    |
      | Serial Number              |
      | MAC-Address                |
      | IMEI-Number                |
      | Name                       |
      | Note                       |
      | Attachments                |
      | - Location -               |
      | Building                   |
      | Room                       |
      | Shelf                      |
      | - Invoice Information -    |
      | Reference                  |
      | Project Number             |
      | Invoice Number             |
      | Invoice Date               |
      | Initial Price              |
      | Supplier                   |
      | Warranty expiration        |
      | Contract expiration        |
      | - Toni Ankunftskontrolle - |
      | Check-In Date              |
      | Check-In State             |
      | Check-In Note              |

  Scenario: Delete supplier
    Given I edit an item that belongs to the current inventory pool
    And I navigate to the edit page of an item that has a supplier
    When I delete the supplier
    And I save
    Then the item has no supplier

  Scenario: Edit all an item's information
    Given I edit an item that belongs to the current inventory pool and is in stock and is not part of any contract
    When I enter the following item information
      | field                  | type         | value               |

      | Inventory Code         |              | Test Inventory Code |
      | Model                  | autocomplete | Sharp Beamer 456    |

      | Retirement             | select       | Yes                 |
      | Reason for Retirement  |              | Some reason         |
      | Working order          | radio        | OK                  |
      | Completeness           | radio        | OK                  |
      | Borrowable             | radio        | OK                  |

      | Relevant for inventory | select       | Yes                 |
    And I save
    Then I am redirected to the inventory list
    And the item is saved with all the entered information

  Scenario: Choosing a model without a version
    Given I edit an item that belongs to the current inventory pool
    And there is a model without a version
    When I assign this model to the item
    Then there is only product name in the input field of the model

  Scenario: Change supplier
    Given I edit an item that belongs to the current inventory pool
    When I change the supplier
    And I save
    Then the edited item has the new supplier

  Scenario: You can't change the responsible department for items that are not in stock
    Given I edit an item that belongs to the current inventory pool and is not in stock
    When I change the responsible department
    And I save
    Then I see an error message that I can't change the responsible inventory pool for items that are not in stock

  @unstable
  Scenario: Editing an item an all its information
    Given I edit an item that belongs to the current inventory pool and is in stock and is not part of any contract
    When I enter the following item information
      | field                  | type         | value               |
      | Inventory Code         |              | Test Inventory Code |
      | Model                  | autocomplete | Sharp Beamer 456    |
      | Relevant for inventory | select       | Yes                 |
      | Move                   | select       | sofort entsorgen    |
      | Target area            |              | Test room           |
      | Check-In Date          |              | 01/01/2013          |
      | Check-In State         | select       | transportschaden    |
      | Check-In Note          |              | Test note           |
      | Serial Number          |              | Test serial number  |
      | MAC-Address            |              | Test MAC address    |
      | IMEI-Number            |              | Test IMEI number    |
      | Name                   |              | Test name           |
      | Note                   |              | Test note           |
      # FIX: IS BROKEN ON CI!!!
      # | Building               | autocomplete | general building  |
      # | Room                   | autocomplete | general room      |
      | Shelf                  |              | Test shelf          |
      | Reference              | radio must   | Investment          |
      | Project Number         |              | Test number         |
      | Invoice Number         |              | Test number         |
      | Invoice Date           |              | 01/01/2013          |
      | Initial Price          |              | 50.00               |
      | Warranty expiration    |              | 01/01/2013          |
      | Contract expiration    |              | 01/01/2013          |
      | Last Checked           |              | 01/01/2013          |
      | Responsible department | autocomplete | A-Ausleihe          |
      | Responsible person     |              | Matus Kmit          |
      | User/Typical usage     |              | Test use            |
    And I save
    Then I am redirected to the inventory list
    And the item is saved with all the entered information

  Scenario: Required fields
    Given I edit an item that belongs to the current inventory pool
    Then "Reference" must be selected in the "Invoice Information" section
    When "Investment" is selected for "Reference", "Project Number" must also be supplied
    When "Yes" is selected for "Retirement", "Reason for Retirement" must also be supplied
    Then all required fields are marked with an asterisk
    And I cannot save the item if a required field is empty
    And I see an error message
    And the required fields are highlighted in red

  Scenario: Do not create a new supplier if one of the same name already exists
    Given I edit an item that belongs to the current inventory pool
    When I enter a supplier
    And I save
    Then no new supplier is created
    And the edited item has the existing supplier

  Scenario: Can't change the model for items that are in contracts
    Given I edit an item that belongs to the current inventory pool and is not in stock
    When I change the model
    And I save
    Then I see an error message that I can't change the model because the item is already handed over or assigned to a contract

  Scenario: Can't retire an item that is not in stock
    Given I edit an item that belongs to the current inventory pool and is not in stock
    When I retire the item
    And I save
    Then I see an error message that I can't retire the item because it's already handed over or assigned to a contract

  Scenario: Delete item
    Given there is a new item in the current inventory pool
    And I edit the item
    When I delete the item
    Then the item was deleted successfully

  Scenario: View attachments (attachments field is readonly)
    Given the attachments field is configured to be editable only by the owner
    And exists an item that belongs to the current inventory pool but is not owned by it
    And the item has 1 attachment
    When I edit the item
    Then I cannot add attachments
    And I cannot remove attachments
    But I can view the attachment when klicking on the filename
