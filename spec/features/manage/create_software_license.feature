Feature: Creating a software license

  Background:
    Given personas dump is loaded
    And I am Mike

  @manage_create_software_license
  Scenario: Input values specification
    Given I navigate to the create software license page
    Then the possible select values for "Activation Type" are as follows:
      | None                         |
      | Dongle                       |
      | Serial Number                |
      | License Server               |
      | Challenge Response/System ID |
    Then the possible select values for "License Type" are as follows:
      | Free               |
      | Single Workplace   |
      | Multiple Workplace |
      | Site License       |
      | Concurrent         |
    Then the possible radio button values for "Borrowable" are as follows:
      | OK           |
      | Unborrowable |
    Then the possible checkbox values for "Operating System" are as follows:
      | Windows          |
      | Mac OS X         |
      | Linux            |
      | iOS              |
    Then the possible checkbox values for "Installation" are as follows:
      | Citrix |
      | Local  |
      | Web    |
    Then the possible radio button values for "Reference" are as follows:
      | Running Account |
      | Investment      |
    Then for "License expiration" one can select a date
    Then the possible select values for "Maintenance contract" are as follows:
      | No  |
      | Yes |
    Then for "Invoice Date" one can select a date
    Then for "Initial Price" one can enter some value
    Then for "Procured by" one can enter some value
    Then for "Supplier" one can choose a value via autocomplete
    Then for "Responsible department" one can choose a value via autocomplete
    Then for "Owner" one can choose a value via autocomplete
    Then for "Note" one can enter some value
    And the default radio button for "Borrowable" is "Unborrowable"

  @manage_create_software_license
  Scenario: Create software license
    Given there is a software
    When I navigate to the create software license page
    Then the inventory code is pre-filled
    When I fill in the software
    And I fill in a serial number
    When I choose dongle as activation type
    Then the field "Dongle ID" is visible
    And the field "Dongle ID" is required
    And I fill in the dongle ID
    When I select 'Multiple Workplace' for license type
    And I fill in the value of total quantity
    And I add a quantity allocation
    And I check 'Linux' for operating system
    And I check 'Local' and 'Web' for installation
    And I set a date for license expiration
    When I select 'No' for maintenance contract
    Then the field "Maintanence expiration" is not visible
    Then the field "Currency" is not visible
    Then the field "Price" is not visible
    When I select 'Yes' for maintenance contract
    And I set a date for maintenance expiration
    When I select radio button 'Investition' for reference
    Then the field "Project Number" is visible
    And the field "Project Number" is required
    And I fill in the project number
    When I select 'OK' for borrowable
    And I save
    Then the license has been saved in the database successfully
