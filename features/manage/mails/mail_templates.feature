Feature: Mail templates

  As an admin or inventory manager
  I want to customize the text of the emails that leihs sends
  So that my users get all information they need
  and so that my leihs instance is unique and matches the rest
  of my organization.

  @rack
  Scenario Outline: Available default templates in english
    Then the default <template name> exists in the database for a given <type> and all languages
  Examples:
    | template name          | type      |
    | approved               | order     |
    | received               | order     |
    | rejected               | order     |
    | submitted              | order     |
    | deadline_soon_reminder | user      |
    | reminder               | user      |


  @rack
  Scenario Outline: Specifying system-wide default templates
    Given I am Gino
    When I specify a mail template for the <template name> action for the whole system for each active language
    And I save
    Then the template <template name> is saved for the whole system for each active language
  Examples:
    | template name          |
    | approved               |
    | received               |
    | rejected               |
    | submitted              |
    | deadline_soon_reminder |
    | reminder               |

  @rack
  Scenario Outline: Specifying mail templates specific to an inventory pool
    Given I am Mike
    When I specify a mail template for the <template name> action in the current inventory pool for each active language
    And I save
    Then the template <template name> is saved for the current inventory pool for each active language
  Examples:
    | template name          |
    | approved               |
    | received               |
    | rejected               |
    | submitted              |
    | deadline_soon_reminder |
    | reminder               |

  @rack
  Scenario Outline: Receiving reminders using the correct mail template
    Given I am Normin
    And I have a contract with deadline <deadline>
    When the reminders are sent
    Then I receive an email formatted according to the <template name> mail template
  Examples:
    | template name          | deadline  |
    | reminder               | yesterday |
    | deadline_soon_reminder | tomorrow  |

  @rack
  Scenario Outline: Mail template language precendence
    Given I am Normin
    And my language is set to "<language>"
    And I have a contract with deadline yesterday
    When the reminders are sent
    Then I receive a reminder in "<received language>"
  Examples:
    | language | received language |
    | de-CH    | de-CH             |
    | en-GB    | en-GB             |

  @rack
  Scenario: How an email template is parsed
    Given I am Normin
    And I have a contract with deadline yesterday for the inventory pool "A-Ausleihe"
    And the reminder mail template looks like
    """
Dear {{ user.name }},

Kind regards,
{{ inventory_pool.name }}
    """
    When the reminders are sent
    Then I receive an email formatted according to the reminder mail template
    And the mail body looks like
    """
Dear Normin Normalo,

Kind regards,
A-Ausleihe
    """

  Scenario Outline: Reporting errors on mail templates
    Given I am <persona>
    When I specify a mail template for the <template name> action <scope> for each active language
    When I edit the <template name> with the "<body>" template in "en-GB"
    And I save
    Then I land on the mail templates edit page
    And I see an error message
    And the failing <template name> mail template in "en-GB" is highlighted in red
    And the failing <template name> mail template in "en-GB" is not persisted with the "<body>" template
  Examples:
    | persona | scope                         | template name | body                |
    | Gino    | for the whole system          | reminder      | Hi {{{ user.name }} |
    | Mike    | in the current inventory pool | reminder      | Hi {{{ user.name }} |

  @rack
  Scenario: Mail templates edit permissions
    Given I am Pius
    When I navigate to the mail templates list in the current inventory pool
    Then I don't see a list of mail templates
    And I see a notification that I don't have sufficient permissions
    Given I am Mike
    When I navigate to the mail templates list in the current inventory pool
    Then I see a list of mail templates
