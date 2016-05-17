Feature: Exporting the data to a CSV-File

  Background:
    Given the basic dataset is ready

  @csv
  Scenario Outline: Export data
    Given I am <username>
    And the budget period has ended
    And following requests exist for the current budget period
      | quantity | user    |
      | 2        | Barbara |
      | 3        | Roger   |
    When I navigate to the requests overview page
    And I export the shown information
    Then the following fields are exported
      | Budget period              |
      | Main category              |
      | Sub category               |
      | Requester                  |
      | Article / Project          |
      | Article nr. / Producer nr. |
      | Replacement / New          |
      | Requested quantity         |
      | Approved quantity          |
      | Order quantity             |
      | Price                      |
      | Total                      |
      | Priority                   |
      | Motivation                 |
      | Supplier                   |
      | Inspection comment         |
      | Receiver                   |
      | Point of Delivery          |
      | State                      |
    Examples:
      | username  |
      | Barbara   |
      | Roger     |
      | Hans Ueli |

  Scenario Outline: Export data when budget period has not yet ended (without approved and order quantity)
    Given I am Roger
    And the budget period has not yet ended
    And following requests exist for the current budget period
      | quantity | user    |
      | 2        | Barbara |
      | 3        | Roger   |
    When I navigate to the requests overview page
    And I export the shown information
    Then the following fields are exported
      | Budget period              |
      | Main category              |
      | Sub category               |
      | Requester                  |
      | Article / Project          |
      | Article nr. / Producer nr. |
      | Replacement / New          |
      | Requested quantity         |
      | Price                      |
      | Total                      |
      | Priority                   |
      | Motivation                 |
      | Supplier                   |
      | Inspection comment         |
      | Receiver                   |
      | Point of Delivery          |
      | State                      |
