Feature: Admin users

  Background:
    Given personas dump is loaded
    And I am Gino

  @leihs_admin_users
  Scenario: Give admin rights to another user (as administrator)
    Given I am editing a user that has no access rights and is not an admin
    When I assign the admin role to this user
    And I save
    Then I see a notification message
    And this user has the admin role
    And all their previous access rights remain intact

  @leihs_admin_users
  Scenario: Remove admin rights from a user, as administrator
    Given I am editing a user who has the admin role and access to inventory pools
    When I remove the admin role from this user
    And I save
    Then this user no longer has the admin role
    And all their previous access rights remain intact

  @leihs_admin_users
  Scenario: Add a new user as an administrator, from outside the inventory pool
    Given I open the list of users
    When I navigate from here to the user creation page
    And I enter the following information
      | First name     |
      | Last name      |
      | E-Mail         |
    And I enter the login data
    And I save
    Then I am redirected to the user list outside an inventory pool
    And I see a notification message
    And the new user has been created
    And he does not have access to any inventory pools and is not an administrator

  @leihs_admin_users
  Scenario: Deleting a user as an administrator
    Given I open the list of users
    And I pick a user without access rights, orders or contracts
    When I delete that user from the list
    Then I see a success message
    And that user has been deleted from the list
    And that user does not exist anymore

  @leihs_admin_users
  Scenario: Access user list within inventory pool inventory pool as an administrator
    Given I do not have access as manager to any inventory pools
    When I open the list of users in an inventory pool
    Then I am redirected to the login page

  @leihs_admin_users
  Scenario: Listing all user's access rights
    Given I open the list of users
    And I edit a user that has access rights
    Then inventory pools they have access to are listed with the respective role

  @leihs_admin_users
  Scenario: Requirements for deleting a user
    Given I open the list of users
    When I pick one user with access rights, one with orders and one with contracts
    Then the delete button for every picked user is not present

  @leihs_admin_users
  Scenario: Searching for a User in "All" Tab
    Given I open the list of users
      And I pick any user
    Then the currently active tab is "All"
    When I search the Users list for the picked users name
    Then I see the picked user in the results
    Then the currently active tab is "All"

  @leihs_admin_users
  Scenario: Searching for a User in "Admin" Tab
  Given I open the list of users
    And I pick an admin user
  When I change the tab to "Administrator"
  Then the currently active tab is "Administrator"
  When I search the Users list for the picked users name
  Then I see the picked user in the results
    And the currently active tab is "Administrator"
