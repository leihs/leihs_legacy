Feature: Edit a hand over

  Background:
    Given I am Pius

  Scenario: Feedback on a successful manual interaction during hand over
    Given there is a hand over with at least one unproblematic model and an option
    And I open the hand over
    When I assign an inventory code to the unproblematic model
    Then the item is assigned to the line
    And the line is selected
    And the line is highlighted in green
    Then I receive a notification of success
    When I deselect the line
    Then the line is no longer highlighted in green
    When I reselect the line
    Then the line is highlighted in green
    When I remove the assigned item from the line
    Then the line is no longer highlighted in green

  Scenario: Feedback on assigning an item to a problematic line
    Given there is a hand over with at least one problematic line
    And I open the hand over
    Then problem notifications are shown for the problematic model
    When I manually assign an inventory code to that line
    And the line is selected
    And the line is highlighted in green
    And the problem notifications remain on the line

  Scenario: Show user's suspended state
    Given I open a hand over
    And the user in this hand over is suspended
    Then I see the note 'Suspended!' next to their name

  Scenario: System feedback when adding an option
    Given I open a hand over
    When I add an option
    Then the line is selected
    And the line is highlighted in green
    And I receive a notification

  Scenario: Handing over an already assigned item
    Given I open a hand over with at least one assigned item
    When I assign an already added item
    Then I see the error message 'XY is already assigned to this contract'
    And the line remains selected
    And the line remains highlighted in green
    And no new line for this model is added

  Scenario: Default contract note
    Given there is a default contract note for the inventory pool
    And I open a hand over with at least one assigned item
    When I hand over the items
    Then a hand over dialog appears
    And the contract note field in this dialog is already filled in with the default note

  Scenario: Contract note
    When I open a hand over with at least one assigned item for a normal user
    And I hand over the items
    Then a dialog appears
    And I can enter some text in the contract note field
    When I enter "something" in the contract note field
    And I click hand over inside the dialog
    Then "something" appears on the contract

  Scenario: Hand over options with at least quantity 1
    When I open a hand over
    And I add an option
    And I change the quantity to "0"
    And I unfocus the option line
    Then the quantity will be restored to the original value
    And I change the quantity to "-1"
    And I unfocus the option line
    Then the quantity will be restored to the original value
    When I change the quantity to "abc"
    And I unfocus the option line
    Then the quantity will be restored to the original value
    And I change the quantity to "2"
    And I unfocus the option line
    Then the quantity will be stored to the value "2"

  Scenario: Displaying serial number while handing over software licenses
    When I open a hand over containing software
    And I click on the assignment field of software names
    Then I see the inventory codes and the complete serial numbers of that software


  # This was never implemented, so not translated.
  #
  # Scenario: Listing problematic items
  #   Given there is a model with a problematic item
  #   And ich öffne eine Aushändigung für irgendeinen Benutzer
  #   When ich diesen Modell der Aushändigung hinzufüge
  #   And ich auf der Modelllinie die Gegenstandsauswahl öffne
  #   Then wird der problematische Gegenstand in rot aufgelistet

  # This was never implemented, so not translated.
  #
  # Scenario: Keine Auflistung von ausgemusterten Gegenständen
  #   Given es existiert ein Modell mit einem ausgemusterten und einem ausleihbaren Gegenstand
  #   And ich öffne eine Aushändigung für irgendeinen Benutzer
  #   When ich diesen Modell der Aushändigung hinzufüge
  #   And ich auf der Modelllinie die Gegenstandsauswahl öffne
  #   Then wird der ausgemusterte Gegenstand nicht aufgelistet

  Scenario: Displaying already assigned items
    Given there is a hand over with at least 21 assigned items for a user
    When I open the hand over
    Then I see the already assigned items and their inventory codes

  Scenario: Assigning an owned item where other pool is responsible
    Given I open a hand over
    And there exists an item owned by the current inventory pool but in responsibility of pool "Another Pool XY"
    When I assign an owned item where other inventory pool is responsible
    Then I see the error message "You do not have the responsibility to lend this item. Responsible for this item is the pool "Another Pool XY"."
