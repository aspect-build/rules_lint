@accountability
@accountability-json
Feature: accountability
  accounts should always be good

  @truncateTables
  Scenario: Check accountability
    # Insert fixtures
    Given the following fixtures files are loaded:
      | 10.contracts.yml |
      | 20.wallet.yml    |
      | 30.tax.yml       |

    Given I inject the header "authorization" with value 'Bearer some-token'

    And I inject the header "accept" with value "application/json"

    # I will create an order here
    Given I create an order
    Then the response status code should be 200
    When I pay the latest order
    And I refund the last payment and transaction list with transactions:
      """
      [{ "name": "card", "credit": 5000 }]
      """
