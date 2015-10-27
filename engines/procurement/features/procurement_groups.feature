Feature: Procurement Groups

  @personas
  Scenario: Creating the Procurement Groups
    Given I am Dani
    Then I can create one or more procurement groups
    When I create a procurement group the following information is needed
    |field|value|
    |name|text|
    |responsible|leihs user|
    And more than one responsible is possible

  @personas
  Scenario: Editing a procurement group
    Given I am Dani
    When I edit a procurement group
    Then I can delete a responsible person
    And I can add a responsible person
    When the procurement group does not yet have any requests
    Then I can change the name of the procurement group

  @personas
  Scenario: Deleting a procurement group
    Given I am Dani
    When a procurement group does not yet have any requests
    Then I can delete the procurement group
