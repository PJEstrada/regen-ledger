Feature: MsgPut

  Credits can be put into a basket:
  - when the basket exists
  - when the credit batch exists
  - when the credit class is allowed
  - when the user has a credit balance
  - when the user has the credit amount
  - when the credit amount does not exceed maximum decimal places
  - when the credit batch start date is more than or equal to minimum start date
  - when the credit batch start date is within or at the limit of start date window
  - when the credit batch start date is more than or equal to years in the past
  - the user credit balance is updated
  - the basket credit balance is updated
  - the user token balance is updated
  - the basket token supply is updated
  - the response includes basket token amount received

  Rule: The basket must exist

    Background:
      Given alice owns credits

    Scenario: basket exists
      Given a basket with denom "NCT"
      When alice attempts to put credits into basket "NCT"
      Then expect no error

    Scenario: basket does not exist
      When alice attempts to put credits into basket "NCT"
      Then expect the error "basket NCT not found: not found"

  Rule: The credit batch must exist

    Background:
      Given a basket

    Scenario: batch denom exists
      Given alice owns credits from credit batch "C01-20200101-20210101-001"
      When alice attempts to put credits from credit batch "C01-20200101-20210101-001" into the basket
      Then expect no error

    Scenario: batch denom does not exist
      When alice attempts to put credits from credit batch "C01-20200101-20210101-001" into the basket
      Then expect the error "could not get batch C01-20200101-20210101-001: not found: invalid request"

  Rule: The credit batch must be from a credit class that is allowed in the basket

    Background:
      Given a basket with allowed credit class "C01"

    Scenario: credit class is allowed
      Given alice owns credits from credit batch "C01-20200101-20210101-001"
      When alice attempts to put credits from credit batch "C01-20200101-20210101-001" into the basket
      Then expect no error

    Scenario: credit class is not allowed
      Given alice owns credits from credit batch "A01-20200101-20210101-001"
      When alice attempts to put credits from credit batch "A01-20200101-20210101-001" into the basket
      Then expect the error "credit class A01 is not allowed in this basket: invalid request"

  Rule: The user must have a credit balance for the credits being put into the basket

    Background:
      Given a basket

    Scenario: user has a credit balance
      Given alice owns credits from credit batch "C01-20200101-20210101-001"
      When alice attempts to put credits from credit batch "C01-20200101-20210101-001" into the basket
      Then expect no error

    Scenario: user does not have a credit balance
      Given alice owns credits from credit batch "C01-20200101-20210101-001"
      When bob attempts to put credits from credit batch "C01-20200101-20210101-001" into the basket
      Then expect error contains "could not get batch C01-20200101-20210101-001 balance"

  Rule: The user must have a credit balance more than or equal to the credits being put into the basket

    Background:
      Given a basket

    Scenario Outline: user owns more than or equal amount of credits being put into the basket
      Given alice owns credit amount "<balance-before>"
      When alice attempts to put credit amount "<credit-amount>" into the basket
      Then expect no error

      Examples:
        | description | balance-before | credit-amount |
        | more than   | 100            | 50            |
        | equal to    | 100            | 100           |

    Scenario: user owns less than amount of credits being put into the basket
      Given alice owns credit amount "100"
      When alice attempts to put credit amount "150" into the basket
      Then expect error contains "cannot put 150 credits into the basket with a balance of 100"

  Rule: Credit amount must not exceed maximum decimal places

    Scenario Outline: credit amount does not exceed maximum decimal places
      Given a basket with exponent "<exponent>"
      And alice owns credit amount "<credit-amount>"
      When alice attempts to put credit amount "<credit-amount>" into the basket with exponent
      Then expect no error

      Examples:
        | description  | exponent | credit-amount |
        | no decimals  | 0        | 2             |
        | one decimal  | 1        | 2.5           |
        | two decimals | 2        | 2.25          |

    Scenario Outline: credit amount exceeds maximum decimal places
      Given a basket with exponent "<exponent>"
      And alice owns credit amount "<credit-amount>"
      When alice attempts to put credit amount "<credit-amount>" into the basket with exponent
      Then expect error contains "exceeds maximum decimal places"

      Examples:
        | description  | exponent | credit-amount |
        | no decimals  | 0        | 2.5           |
        | one decimal  | 1        | 2.25          |
        | two decimals | 2        | 2.333         |

  Rule: Credits from a batch with a start date more than basket minimum start date cannot be put into the basket

    Background:
      Given a basket with minimum start date "2021-01-01"

    Scenario Outline: batch start date less than or equal to minimum start date
      Given alice owns credits with start date "<batch-start-date>"
      When alice attempts to put credits into the basket
      Then expect no error

      Examples:
        | description | batch-start-date |
        | less than   | 2022-01-01       |
        | equal to    | 2021-01-01       |

    Scenario: batch start date more than minimum start date
      Given alice owns credits with start date "2020-01-01"
      When alice attempts to put credits into the basket
      Then expect error contains "cannot put a credit from a batch with start date"

  Rule: Credits from a batch with a start date outside basket start date window cannot be put into the basket

    Background:
      Given the block time "2022-01-01"
      And a basket with start date window "31536000"

    Scenario Outline: batch start date within or at the limit of basket start date window
      Given alice owns credits with start date "<batch-start-date>"
      When alice attempts to put credits into the basket
      Then expect no error

      Examples:
        | description | batch-start-date |
        | less than   | 2022-01-01       |
        | equal to    | 2021-01-01       |

    Scenario: batch start date outside of basket start date window
      Given alice owns credits with start date "2020-01-01"
      When alice attempts to put credits into the basket
      Then expect error contains "cannot put a credit from a batch with start date"

  Rule: Credits from a batch with a start date more than basket years in the past cannot be put into the basket

    Scenario Outline: batch start date less than or equal to years in the past
      Given the block time "2022-04-01"
      And a basket with years in the past "10"
      And alice owns credits with start date "<batch-start-date>"
      When alice attempts to put credits into the basket
      Then expect no error

      Examples:
        | description             | batch-start-date |
        | year equal, day before  | 2012-01-01       |
        | year equal, day equal   | 2012-04-01       |
        | year equal, day after   | 2012-07-01       |
        | year after, day before  | 2013-01-01       |
        | year after, day equal   | 2013-04-01       |
        | year after, day after   | 2013-07-01       |

    Scenario Outline: batch start date more than years in the past
      Given the block time "2022-04-01"
      And a basket with years in the past "10"
      And alice owns credits with start date "<batch-start-date>"
      When alice attempts to put credits into the basket
      Then expect error contains "cannot put a credit from a batch with start date"

      Examples:
        | description             | batch-start-date |
        | year before, day before | 2011-01-01       |
        | year before, day equal  | 2011-04-01       |
        | year before, day after  | 2011-07-01       |

  Rule: The user credit balance is updated when credits are put into the basket

    Scenario: user credit balance is updated
      Given a basket
      And alice owns credit amount "100"
      When alice attempts to put credit amount "100" into the basket
      Then alice has a credit balance with amount "0"

    # no failing scenario - state transitions only occur upon successful message execution

  Rule: The basket credit balance is updated when credits are put into the basket

    Scenario: basket credit balance is updated
      Given a basket
      And alice owns credit amount "100"
      When alice attempts to put credit amount "100" into the basket
      Then the basket has a credit balance with amount "100"

    # no failing scenario - state transitions only occur upon successful message execution

 Rule: The user token balance is updated when credits are put into the basket

    Scenario Outline: user token balance is updated
      Given a basket with exponent "<exponent>"
      And alice owns credit amount "<credit-amount>"
      When alice attempts to put credit amount "<credit-amount>" into the basket with exponent
      And alice has a basket token balance with amount "<token-amount>"

      Examples:
        | description                       | exponent | credit-amount | token-amount |
        | exponent zero, amount whole       | 0        | 2             | 2            |
        | exponent non-zero, amount whole   | 6        | 2             | 2000000      |
        | exponent non-zero, amount decimal | 6        | 2.5           | 2500000      |

    # no failing scenario - state transitions only occur upon successful message execution

 Rule: The basket token supply is updated when credits are put into the basket

    Scenario Outline: basket token supply is updated
      Given a basket with exponent "<exponent>"
      And alice owns credit amount "<credit-amount>"
      When alice attempts to put credit amount "<credit-amount>" into the basket with exponent
      Then the basket token has a total supply with amount "<token-amount>"

      Examples:
        | description                       | exponent | credit-amount | token-amount |
        | exponent zero, amount whole       | 0        | 2             | 2            |
        | exponent non-zero, amount whole   | 6        | 2             | 2000000      |
        | exponent non-zero, amount decimal | 6        | 2.5           | 2500000      |

    # no failing scenario - state transitions only occur upon successful message execution

 Rule: The message response includes basket token amount received when credits are put into the basket

    Scenario Outline: message response includes basket token amount received
      Given a basket with exponent "<exponent>"
      And alice owns credit amount "<credit-amount>"
      When alice attempts to put credit amount "<credit-amount>" into the basket with exponent
      Then expect the response
      """
      {
        "amount_received": "<token-amount>"
      }
      """

      Examples:
        | description                       | exponent | credit-amount | token-amount |
        | exponent zero, amount whole       | 0        | 2             | 2            |
        | exponent non-zero, amount whole   | 6        | 2             | 2000000      |
        | exponent non-zero, amount decimal | 6        | 2.5           | 2500000      |

    # no failing scenario - response should always be empty when message execution fails