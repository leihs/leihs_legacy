Feature: Create first admin user

  @manage_create_first_admin_user
  Scenario: Show login page as root path if user exists
    Given a user exists
    And a database authentication system exists
    And this authentication system is active and default
    When I visit the root path
    Then the root page with the login button is displayed

  @manage_create_first_admin_user
  Scenario: Create and login in as first admin user
    Given a user does not exist
    And a database authentication system does not exist
    When I visit the root path
    Then the create first admin user page is displayed
    When I fill in the firstname
    And I fill in the lastname
    And I fill in the email
    And I fill in the login
    And I fill in the password
    And I fill in the password confirmation
    And I click on save
    Then the root page with the login button is displayed
    And there is notice about successful creation of the admin user and the database authentication system
    When I click on login
    Then the login form is displayed
    When I fill in the login of the created admin user
    And I fill in the password of the created admin user
    And I click on login
    Then I have been successfully logged in as the created admin user
    And I see the admin section

  @manage_create_first_admin_user
  Scenario: Retain and update already existing authentication systems
    Given a user does not exist
    And non-default database authentication system exists
    And some other default authentication system exists
    When I visit the root path
    When I fill in the firstname
    And I fill in the lastname
    And I fill in the email
    And I fill in the login
    And I fill in the password
    And I fill in the password confirmation
    And I click on save
    Then the database authentication system has been set to default
    And the other authentication system is not default anymore

  @manage_create_first_admin_user
  Scenario: Forbid the access to first admin user page if admin access right exists
    Given a user exists
    When I visit the first admin user page
    Then I see a message "Admin user already exists!"
