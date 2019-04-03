Feature: Availability example

  Background:
    Given personas dump is loaded

  @availability_example
  Scenario: Basic
    Given basic data file is loaded
    And I visit "/"
    And eval "@user = Example.instance_eval { @inventory_manager }"
    When I am logged in as the user
    And I visit the old timeline for the model

  @availability_example
  Scenario: Soft overbooking
    Given basic data file is loaded
    And soft overbooking file is loaded
    And eval "@user = Example.instance_eval { @inventory_manager }"
    When I am logged in as the user
    And I visit the old timeline for the model

  @availability_example
  Scenario: Hard overbooking
    Given basic data file is loaded
    And hard overbooking file is loaded
    And eval "@user = Example.instance_eval { @inventory_manager }"
    When I am logged in as the user
    And I visit the old timeline for the model
