Feature: Rooms

  @leihs_admin_rooms
  Scenario: Listing existing rooms
    Given I am logged in as admin
    And there exists a room "Room A" for building "Building A"
    And this room has 1 item
    And there exists a room "Room B" for building "Building A"
    And there exists a room "Room A" for building "Building B"
    And there exists a room "Room B" for building "Building B"
    When I visit the list of rooms
    Then I see the list of rooms sorted in the following manner:
      | room_name    | building_name |
      | general room | Building A    |
      | Room A       | Building A    |
      | Room B       | Building A    |
      | general room | Building B    |
      | Room A       | Building B    |
      | Room B       | Building B    |
    And each room line displays the number of items placed in it
    And each general room line displays the general label in it
    And each general room line is highlighted
    And the edit button

  @leihs_admin_rooms
  Scenario: Editing a room
    Given I am logged in as admin
    And there exists a room
    And there exists a building
    When I visit the list of rooms
    And I click on the edit button for the row of the room
    Then I see the edit room page
    When I enter the name
    And I enter the description
    And I choose the building from the select box
    And I click on "Save"
    Then I am redirected to the list of rooms
    And I see a notification message
    And the room was saved successfully

  @leihs_admin_rooms
  Scenario: Creating a room
    Given I am logged in as admin
    And there exists a building
    When I visit the list of rooms
    And I click on create room button
    Then I see the create room page
    When I enter the name
    And I enter the description
    And I choose the building from the select box
    And I click on "Save"
    Then I am redirected to the list of rooms
    And I see a notification message
    And the room was created successfully

  @leihs_admin_rooms
  Scenario: Checking uniqueness in regards to name and building
    Given I am logged in as admin
    And there exists a room "Room A" for building "Building A"
    When I visit the list of rooms
    And I click on create room button
    Then I see the create room page
    When I enter the name "Room A"
    And I choose the building "Building A" from the select box
    And I click on "Save"
    Then I see an error message
    And a second room with name "Room A" and building "Building A" was not created

  @leihs_admin_rooms
  Scenario: Checking presence of name
    Given I am logged in as admin
    And there exists a building "Building"
    When I visit the list of rooms
    And I click on create room button
    Then I see the create room page
    When I enter the name ""
    And I choose the building "Building" from the select box
    And I click on "Save"
    Then I see an error message
    And the room with name "" and building "Building" was not created

  @leihs_admin_rooms
  Scenario: Checking presence of building
    Given I am logged in as admin
    When I visit the list of rooms
    And I click on create room button
    Then I see the create room page
    And I click on "Save"
    Then I see an error message

  @leihs_admin_rooms
  Scenario: Deleting a room with items is not possible
    Given I am logged in as admin
    And there exists a room
    And this room has 1 item
    When I visit the list of rooms
    Then I don't see the delete button on the row for the room

  @leihs_admin_rooms
  Scenario: Deleting a room
    Given I am logged in as admin
    And there exists a room
    When I visit the list of rooms
    And I click on the delete button for the room
    And I confirm the dialog
    Then I am redirected to the list of rooms
    And the room was deleted successfully

  @leihs_admin_rooms
  Scenario: Changing of the building for the general room should not be possible
    Given personas dump is loaded
    And I am logged in as admin
    When I visit the edit page of a general room
    Then I see the edit room page
    And I cannot choose the building from the select box

  @leihs_admin_rooms
  Scenario: Deleting the general room is not possible
    Given personas dump is loaded
    And I am logged in as admin
    And there is a general room
    And there are no items for the general room
    When I visit the list of rooms
    And I search for the name of the general room
    And I scrool down until I see the line for the general room
    Then I don't see the delete button on the row for the room
