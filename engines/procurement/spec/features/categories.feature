Feature: Procurement Categories

  @categories
  Scenario: Creating the main categories
    Given I am Hans Ueli
    And a budget period exist
    And an upcoming budget period exists
    When I navigate to the categories page
    And I click on the add button
    And I fill in the category name
    And I fill in the budget limit for the current budget period
    And I fill in the budget limit for the upcoming budget period
    And I click on save
    Then I see a success message
    And I stay on the main categories edit page
    And the new category appears in the list
    And the new main category was created in the database

  @categories
  Scenario: Creating the sub categories
    Given I am Hans Ueli
    And a main category exists
    And there exists 2 users to become the inspectors
    When I navigate to the categories edit page
    And I click on the add sub category button
    And I fill in the sub category name
    And I fill in the inspectors' names
    And I click on save
    Then I see a success message
    And I stay on the main categories edit page
    And the new sub category with its inspectors was created in the database

  @categories
  Scenario: Editing a main category
    Given I am Hans Ueli
    And there exists a main category
    And there exists 2 budget limits for the category
    And there exists an extra budget period
    When I navigate to the categories edit page
    And I modify the name
    And I delete a budget limit
    And I add a budget limit
    And I modify a budget limit
    And I click on save
    Then I see a success message
    And I stay on the main categories edit page
    And all the information of the category was successfully updated in the database

  @categories
  Scenario: Editing a sub category
    Given I am Hans Ueli
    And a sub category exists
    And the sub category has an inspector
    When I navigate to the categories edit page
    And I modify the name of the sub category
    And I delete the inspector
    And I add another inspector
    And I click on save
    Then I see a success message
    And I stay on the main categories edit page
    And all the information of the category was successfully updated in the database

  @categories
  Scenario: Deleting a main category
    Given I am Hans Ueli
    And there exists a sub category without any requests
    When I navigate to the categories page
    And I delete the main category
    Then I am asked whether I really want to delete the main and the sub category
    When I say yes
    Then the main and the sub categories disappear from the list
    And the categories are successfully deleted from the database

  @categories
  Scenario: Deleting a main category with sub categories containing requests not possible
    Given I am Hans Ueli
    And there exists a main category
    And there exists a sub category for this main category
    And there exist requests for this sub category
    When I navigate to the categories page
    Then I can not delete the main category

  @categories
  Scenario: Deleting a sub category without existing requests
    Given I am Hans Ueli
    And there exists a sub category without any requests
    And there exist templates for this sub category
    When I navigate to the categories page
    And I delete the sub category
    # really ?? not enough with red background and save button ?
    Then I am asked whether I really want to delete the sub category
    When I say yes
    Then the sub category disappears
    And the sub category is successfully deleted from the database
    And the templates are sucessfully deleted from the database

  @categories
  Scenario: Deleting a sub category with existing requests not possible
    Given I am Hans Ueli
    And there exists a sub category
    And there exist requests for this sub category
    When I navigate to the categories page
    Then I can not delete the main category

  @categories
  Scenario: Sorting of categories
    Given I am Hans Ueli
    And 3 main categories exist
    And each main category has two sub categories
    And I navigate to the categories page
    Then the main categories are sorted 0-10 and a-z
    And the sub categories are sorted 0-10 and a-z

  @categories
  Scenario: Overview of the categories
    Given I am Hans Ueli
    And there exists a category
    When I navigate to the categories page
    Then the category line contains the name of the category
    And the sub category line contains the name of the category
    And the sub category line contains the names of the inspectors

  @categories
  Scenario: main category required fields
    Given I am Hans Ueli
    And there does not exist any category yet
    And a current budget period exists
    When I navigate to the categories page
    And I click on the add button
    And I click on save
    Then the name field is marked red
    And I see an error message
    And the new category has not been created

  @categories
  Scenario: sub category required fields
    Given I am Hans Ueli
    And there does not exist any category yet
    And there exist 1 user to become the inspector
    When I navigate to the categories page
    And I click on the add button
    And I start typing the name of the category
    Then the inspector field turns red
    When I delete what has been typed
    And I start typing the inspectors' name
    Then the mandatory name field turns red
    When I fill in the inspector's name
    And I leave the name of the category empty
    And I click on save
    Then the name is still marked red
    And the new category has not been created
