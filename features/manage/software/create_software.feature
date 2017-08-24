Feature: Creating software

  Background:
    Given I am Mike

  Scenario: Creating a software product
    When I add a new Software
    And I enter the following details
      | Field                | Value                                                                        |
      | Product              | Test Software                                                                |
      | Version              | Test Version                                                                 |
      | Software Information | Installationslink beachten: http://wwww.dokuwiki.ch\n\nDies ist nur ein Text |
    When there exists already a manufacturer
    Then the manufacturer can be selected from the list
    When I set a non existing manufacturer
    And I save
    Then the new software product is created and can be found in the software section
    When I edit again this software product
    Then outside the the text field, all the URLs extracted from the software information field are displayed as links
    And the new manufacturer can be found in the manufacturer list

  Scenario: Choosing a license for multiple/concurrent/site licenses
    Given a software product exists
    When I add a new Software License
    And I fill in all the required fields for the license
    When I choose one of the following license types
      | Multiple Workplace   |
      | Concurrent |
      | Site License |
    And I fill in total quantity with value "50"
    Then I see the remaining number of licenses shown as follows "remaining 50"
    And I add the following quantity allocations:
      | Quantity   | Text |
      | 1        | Christina Meier|
      | 10       | Room ITZ.Z40|
    Then I see the remaining number of licenses shown as follows "remaining 39"
    And I add the following quantity allocations:
      | Quantity   | Text |
      | 40       | Raum Z50 |
    Then I see the remaining number of licenses shown as follows "remaining -1"
    When I delete the following quantity allocations:
      | Quantity   | Text |
      | 1        | Christina Meier|
    Then I see the remaining number of licenses shown as follows "remaining 0"

  Scenario: Software-Lizenz Anschaffungswert mit 2 Dezimalstellen erfassen
    Given a software product exists
    When I add a new Software License

    And I fill in all the required fields for the license
    And I fill in the field "Initial Price" with the value "1200"
    And I save
    Then "Initial Price" is saved as "1,200.00"

  Scenario: Add and remove attachments (attachments field is writable)
    When I add a new Software License
    And I fill in all the required fields for the license
    And I add 2 attachments
    And I remove one attachment
    And I save
    Then I am redirected to the inventory list
    And 1 attachment is saved
