Feature: Story 1.8 — Upgrade modal shows preview and upgrade failures
  As a Standard subscriber, I want to see what went wrong if the upgrade cannot be previewed or applied, so
  that I can try again without losing my place.
  Covers: REQ-F-12, REQ-F-15, REQ-NF-03

  Background:
    Given "tpg@example.com" is signed in on the Billing page on plan "Standard"

  @AC-1
  Scenario Outline: A failed preview shows an error and keeps Confirm disabled
    Given the server will answer GET "/api/billing/upgrade/preview" with <failure>
    When the user clicks "Upgrade to Premium"
    Then the dialog shows the message "<message>"
    And the "Confirm Upgrade" button is disabled

    Examples:
      | failure                                                   | message                                  |
      | status 400 and detail "Already on Premium plan"           | Already on Premium plan                  |
      | status 500 and detail "Internal server error"             | Internal server error                    |
      | a network error                                           | Something went wrong. Please try again.  |

  @AC-2
  Scenario Outline: A failed upgrade keeps the dialog open and the page unchanged
    Given the upgrade dialog shows a charge of "$10.00"
    And the server will answer POST "/api/billing/upgrade" with <failure>
    When the user clicks "Confirm Upgrade"
    Then the dialog is still open and shows the message "<message>"
    And the "Confirm Upgrade" button is enabled again
    And the page still shows plan "Standard" at "$20/month"

    Examples:
      | failure                                                   | message                                  |
      | status 400 and detail "Already on Premium plan"           | Already on Premium plan                  |
      | a network error                                           | Something went wrong. Please try again.  |

  @AC-3
  Scenario: Confirm cannot send the upgrade twice
    Given the upgrade dialog shows a charge of "$10.00"
    And the server is slow to answer POST "/api/billing/upgrade"
    When the user clicks "Confirm Upgrade" twice
    Then the "Confirm Upgrade" button is disabled while the request is in flight
    And exactly one POST "/api/billing/upgrade" request was sent

  @AC-4
  Scenario: Error messages are announced to screen readers
    Given the server will answer GET "/api/billing/upgrade/preview" with a network error
    When the user clicks "Upgrade to Premium"
    Then the message "Something went wrong. Please try again." is inside an element with role "alert"
