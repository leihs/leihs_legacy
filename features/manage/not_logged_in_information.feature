
Feature: Redirect to login when not logged in

  As any user
  In order to perform actions inside the system with the proper privileges given to me
  I want to authenticate to the system so I can prove who I am

  Scenario: Trying to perform an action without being logged in
    Given I am Pius
    When I start a handover in the manage area and remember the browser URL-path
    And I am logged out
    And I try to perform an action without being logged in
    Then I am redirected to the sign-in page
    And The return-to parameter is filled out with the browser URL-path I remembered
