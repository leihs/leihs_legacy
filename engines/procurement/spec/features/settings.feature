Feature: General Settings

  @settings
  Scenario: Creating a contact link
    Given I am Hans Ueli
    And I navigate to the settings page
    When I enter the following settings
      | key         | value                         |
      | contact_url | https://www.zhdk.ch/?finanzen |
    And I click on save
    Then I see a success message
    And the settings are saved successfully to the database
    And the contact link is visible

  @settings
  Scenario: Setting "canned responses" for inspection comments
    Given I am Hans Ueli
    And I navigate to the settings page
    # NOTE: just because we need to fill the required field!
    And I enter the following settings
      | key         | value                         |
      | contact_url | https://www.zhdk.ch/?finanzen |
    When I enter the following text in the field "inspection_comments"
      """
      First Comment

      Second Comment
      Another One
      """

    And I click on save
    Then I see a success message
    And these settings are saved in the database as listed
      | key                 | value                                            |
      | inspection_comments | ["First Comment","Second Comment","Another One"] |
