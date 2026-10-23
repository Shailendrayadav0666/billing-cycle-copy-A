Feature: Story 1.2 — Premium users cannot preview or upgrade again
  As a Premium subscriber, I want the app to never offer or apply an upgrade I already have, so that I am
  never charged twice.
  Covers: REQ-F-07, REQ-F-08, REQ-F-10, REQ-NF-01

  Background:
    Given today is "Oct 15, 2026" on the server
    And the seeded user "tpg@example.com" has upgraded to "Premium" renewing on "Oct 30, 2026"
    And "tpg@example.com" is signed in with session token "S1"

  @AC-1
  Scenario: The preview is refused for a Premium subscriber
    When the client sends GET "/api/billing/upgrade/preview" with token "S1"
    Then the response status is 400
    And the response detail is "Already on Premium plan"

  @AC-2
  Scenario: A second upgrade is refused and nothing changes
    When the client sends POST "/api/billing/upgrade" with token "S1"
    Then the response status is 400
    And the response detail is "Already on Premium plan"
    And GET "/api/billing" with token "S1" still returns plan_name "Premium", price "$40/month" and renew_at "Oct 30, 2026"

  @AC-3
  Scenario: The Billing page offers no upgrade to a Premium subscriber
    When "tpg@example.com" opens the Billing page
    Then the "Current plan" badge reads "Premium"
    And no "Upgrade to Premium" button is shown

  @AC-4
  Scenario: An upgrade only changes the caller's own account
    Given "a@example.com" and "b@example.com" are registered Standard users with sessions "SA" and "SB"
    When the client sends POST "/api/billing/upgrade" with token "SA" and body {"email": "b@example.com"}
    Then the response status is 200
    And GET "/api/billing" with token "SA" returns plan_name "Premium"
    And GET "/api/billing" with token "SB" returns plan_name "Standard"
