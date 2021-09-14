Feature: Contracts

  Background:
    Given personas dump is loaded

  @borrow_contracts
  Scenario: Opening a contract of user's delegation
    Given I am logged in as customer
    When I visit a contract of user's delegation
    Then I see the contract

  @borrow_contracts
  Scenario: Opening a contract of not user's delegation
    Given I am logged in as customer
    When I visit a contract of not user's delegation
    Then I see "Contract not found neither for the user nor for his or her delegations."
