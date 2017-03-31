Feature: Field

  Model test (instance methods)

  @rack
  Scenario: Provides the value of an item's attribute that is specified in the field
    Given an item is existing
    Then each field provides the value of the item's attribute

  @rack
  Scenario: Provides values even if the values attribute of a field is a lambda/proc
    Then each field is capable of providing values even if its values attribute is a lambda/proc
