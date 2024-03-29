# TODO remove and test on spec/models/model/availability/model_spec.rb

Feature: Availability depending on Pools

  As an Inventory Manager
  I want to be sure that a customer only gets to see models from inventory pools he has access to
  In order to prevent a customer from ordering things he cannot borrow

  Background:
    Given the database has only minimal seeds
    And settings exist

  @rack
  Scenario: Basic
    Given 2 inventory pools
    And a model 'Coffee Mug' exists
    And this model has 2 items in inventory pool 1
    And this model has 3 items in inventory pool 2
    And customer 'joe' has access to inventory pool 1
    And customer 'jack' has access to inventory pool 1 and 2
    And customer 'john' has access to inventory pool 2
    Then the maximum number of available 'Coffee Mug' for 'joe' is 2
    And the maximum number of available 'Coffee Mug' for 'jack' is 5
    And the maximum number of available 'Coffee Mug' for 'john' is 3

  @rack
  Scenario: Items available in different pools
    Given 2 inventory pools
    And a model 'Coffee Mug' exists
    And this model has 2 items in inventory pool 1
    And this model has 3 items in inventory pool 2
    And a model 'Coffee Machine' exists
    And this model has 1 item in inventory pool 1
    And customer 'jack' has access to inventory pool 1 and 2
    When 'jack' orders 2 'Coffee Mug' from inventory pool 1
    And 'jack' orders 1 'Coffee Machine' from inventory pool 1
    And all reservations of 'jack' are submitted
    Then 1 order exists for inventory pool 1
    And it asks for 3 items
    And 0 orders exist for inventory pool 2

# Scenario: Splitting order and notifying customer
#        Given 2 inventory pools
#                And a model 'Coffee Mug' exists
#                And this model has 3 items in inventory pool 2
#                And a model 'Coffee Machine' exists
#                And this model has 1 items in inventory pool 1
#                And customer 'jack' has access to inventory pool 1 and 2
#        When 'jack' orders 3 'Coffee Mug'
#                And 'jack' orders 1 'Coffee Machine'
#                And he submits the new order
#        Then 1 order exists for inventory pool 1
#                And it asks for 1 item
#                And 1 order exists for inventory pool 2
#                And it asks for 3 items
#                And customer 'jack' gets notified that his order has been submitted

# Scenario: Customer can't order things that he can't see
#        Given 2 inventory pools
#                And a model 'Coffee Mug' exists
#                And this model has 3 items in inventory pool 2
#                And a model 'Coffee Machine' exists
#                And this model has 1 items in inventory pool 1
#                And customer 'jack' has access to inventory pool 1
#        When 'jack' searches for 'Coffee Mug' on frontend
#        Then he gets an empty result set
#        When 'jack' searches for 'Coffee' on frontend
#        Then he sees the 'Coffee Machine' model

  @rack
  Scenario: Customer orders the same item multiple times, thus exceeding maximum quantity
    Given 1 inventory pool
    And a model 'Pink Hairbrush' exists
    And this model has 3 items in inventory pool 1
    And customer 'samantha' has access to inventory pool 1
    When 'samantha' orders 3 'Pink Hairbrush' from inventory pool 1
    Then this user has 3 unsubmitted reservations, which 3 are available
    When 'samantha' orders 2 'Pink Hairbrush' from inventory pool 1 for the same time
    Then this user has 5 unsubmitted reservations, which 0 are available

  @rack
  Scenario: Customer can decide from which pool he orders
    Given 2 inventory pools
    And a model 'Coffee Mug' exists
    And this model has 3 items in inventory pool 1
    And this model has 1 items in inventory pool 2
    And customer 'jack' has access to inventory pool 1
    And customer 'jack' has access to inventory pool 2
    When 'jack' orders 2 'Coffee Mug' from inventory pool 1
    Then this user has 2 unsubmitted reservations, which 2 are available
    When 'jack' orders 2 'Coffee Mug' from inventory pool 2
    Then this user has 4 unsubmitted reservations, which 2 are available
