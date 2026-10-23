Feature: Story 1.9 — Billing page shows a load error with Retry
  As a subscriber, I want to see an error and a way to retry when my billing details fail to load, so that I
  am not left on an endless loading message.
  Covers: REQ-F-15, REQ-NF-03

  Background:
    Given "tpg@example.com" is signed in

  @AC-1
  Scenario Outline: A failed billing load shows an error with Retry instead of endless loading
    Given the server will answer GET "/api/billing" with <failure>
    When the user opens the Billing page
    Then the page shows the message "<message>" and a "Retry" button
    And the text "Loading billing..." is not shown

    Examples:
      | failure                                        | message                                  |
      | status 500 and detail "Internal server error"  | Internal server error                    |
      | a network error                                | Something went wrong. Please try again.  |

  @AC-2
  Scenario: Retry recovers once the server answers
    Given the Billing page shows the load error with a "Retry" button
    And the server will now answer GET "/api/billing" normally
    When the user clicks "Retry"
    Then the page shows plan "Standard" at "$20/month" renewing on "Oct 30, 2026"
    And the error message is no longer shown

  @AC-3
  Scenario: The load error is announced to screen readers
    Given the server will answer GET "/api/billing" with a network error
    When the user opens the Billing page
    Then the message "Something went wrong. Please try again." is inside an element with role "alert"
