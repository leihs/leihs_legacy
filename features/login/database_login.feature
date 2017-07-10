Feature: Login through database authentication

  In order to login
  As a normal user
  I want to be able to login using a database authentication

  @rack
  Scenario: Login through database authentication
    Given I log out
    When I visit the homepage
    And I login as "Normin" via web interface
    Then I am logged in

  Scenario: Login through database authentication in browser using keyboard
    Given I log out
    When I visit the homepage
    And I login as "Normin" via web interface using keyboard
    Then I am logged in

  #80098490
  Scenario: Changing my own password
    Given I am Normin
    And my authentication system is "DatabaseAuthentication"
    When I hover over my name
    And I click "User data"
    Then I get to the "User Data" page
    And I can see my user data
    And I change my password
    Then my password is changed
