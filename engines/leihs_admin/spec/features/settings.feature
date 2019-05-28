Feature: Defining application settings through web interface

  Background:
    Given personas dump is loaded

  @leihs_admin_settings
  Scenario: Editing all the settings
    Given I am Ramon
    When I go to the settings page
    Then I am on the settings page
    And I edit the following settings
      | contract_lending_party_string        |
      | contract_terms                       |
      | default_email                        |
      | deliver_received_order_notifications |
      | email_signature                      |
      | local_currency_string                |
      | logo_url                             |
      | mail_delivery_method                 |
      | smtp_address                         |
      | smtp_domain                          |
      | smtp_enable_starttls_auto            |
      | smtp_openssl_verify_mode             |
      | smtp_password                        |
      | smtp_port                            |
      | smtp_username                        |
      | time_zone                            |
      | user_image_url                       |
    And the settings are persisted

  @leihs_admin_settings
  Scenario: Configure a Link for Logo in Footer
      Given I am Mike
      And I have the roles
       | admin | inventory_manager |

    When I go to the settings page
      And I fill in the "documentation_link" with " "
      And I save the settings
    Then the logo in the footer (in "borrow") has no link
      And the logo in the footer (in "manage") has no link
      And the logo in the footer (in "admin") has no link

    When I go to the settings page
      And I fill in the "documentation_link" with "not a valid uri"
      And I save the settings
    Then I get an error message "Documentation link is not a valid URL"

    When I go to the settings page
      And I fill in the "documentation_link" with "gopher://leihs.pizza"
      And I save the settings
    Then I get an error message "Documentation link is not a HTTP(S) URL"

    When I go to the settings page
      And I fill in the "documentation_link" with "http://ausleihe.example.com/"
      And I save the settings
    Then I get a message "Successfully set."
      And the logo in the footer (in "borrow") has the link "http://ausleihe.example.com/"
      And the logo in the footer (in "manage") has the link "http://ausleihe.example.com/"
      And the logo in the footer (in "admin") has the link "http://ausleihe.example.com/"
