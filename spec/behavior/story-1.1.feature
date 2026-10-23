Feature: Story 1.1 — Upgrade from Standard to Premium on the Billing page
  As a Standard subscriber, I want to upgrade to Premium from the Billing page and see the prorated charge
  before I confirm, so that I get Premium features immediately and only pay for the days left in my cycle.
  Covers: REQ-F-01, REQ-F-02, REQ-F-04, REQ-F-05, REQ-F-06, REQ-F-07, REQ-F-08, REQ-F-09, REQ-F-10,
  REQ-F-11, REQ-F-12, REQ-F-14, REQ-F-16, REQ-NF-01, REQ-NF-02, REQ-NF-04, REQ-NF-05, REQ-NF-06

  Background:
    Given today is "Oct 15, 2026" on the server
    And the seeded user "tpg@example.com" with password "password" is on plan "Standard" at "$20/month" renewing on "Oct 30, 2026"

  @AC-1
  Scenario: A Standard subscriber sees the upgrade button and plan labels from their data
    Given "tpg@example.com" is signed in
    When they open the Billing page
    Then the "Current plan" badge reads "Standard"
    And the heading reads "What's included with Standard"
    And an "Upgrade to Premium" button is shown below the current plan card

  @AC-2
  Scenario: The modal shows the server-calculated prorated charge before anything changes
    Given "tpg@example.com" is signed in and on the Billing page
    When they click "Upgrade to Premium"
    Then a dialog shows "Standard ($20/mo)" and "Premium ($40/mo)"
    And it shows "15 days remaining in your cycle"
    And it shows "You'll be charged $10.00 today for the 15 days remaining in your cycle."
    And it shows a "Confirm Upgrade" button and a "Cancel" button
    And "/api/billing" for "tpg@example.com" still returns plan "Standard"

  @AC-2
  Scenario: The preview endpoint returns the charge for the session's user
    Given "tpg@example.com" is signed in with a session token
    When the client sends GET "/api/billing/upgrade/preview" with that token
    Then the response status is 200
    And the response has current_plan "Standard", new_plan "Premium", days_remaining 15, days_in_cycle 30, prorated_charge 10.00 and renew_at "Oct 30, 2026"

  @AC-3
  Scenario: Confirming the upgrade switches the account to Premium and updates the page without a reload
    Given "tpg@example.com" is signed in and the upgrade dialog shows a charge of "$10.00"
    When they click "Confirm Upgrade"
    Then the page is not reloaded
    And the "Current plan" badge reads "Premium"
    And the heading reads "What's included with Premium"
    And the monthly price shows "$40/month"
    And the renewal date still shows "Oct 30, 2026"
    And the feature cards show "4K Ultra HD", "Can watch on 4 devices at once" and "Can download on 6 devices"
    And the plan perks include "Dolby Vision (select titles)"
    And no "Upgrade to Premium" button is shown
    And the message "You're now on Premium! Your next full cycle bills at $40/month." is shown

  @AC-3
  Scenario: The upgrade endpoint applies the Premium plan and keeps the renewal date
    Given "tpg@example.com" is signed in with a session token
    When the client sends POST "/api/billing/upgrade" with that token
    Then the response status is 200
    And the response has plan_name "Premium", price "$40/month", renew_at "Oct 30, 2026" and prorated_charge 10.00
    And GET "/api/users/me" with that token returns plan "Premium" and price "$40/month"
    And GET "/api/billing" with that token returns plan_name "Premium" and renew_at "Oct 30, 2026"

  @AC-4
  Scenario: Signing in returns an opaque session token, not the email
    When the client signs in as "tpg@example.com" with password "password"
    Then the response status is 200
    And access_token is not "tpg@example.com" and does not contain "tpg@example.com"
    And access_token is at least 43 characters long
    And the response user has no password field

  @AC-4
  Scenario Outline: Protected endpoints reject requests without a valid session
    When the client sends <method> "<path>" with <credential>
    Then the response status is 401
    And the response detail is "Not authenticated"

    Examples:
      | method | path                          | credential                              |
      | GET    | /api/users/me                 | no Authorization header                 |
      | GET    | /api/users/me?email=tpg@example.com | no Authorization header           |
      | GET    | /api/billing                  | Bearer token "not-a-real-token"         |
      | GET    | /api/billing?email=tpg@example.com | no Authorization header            |
      | GET    | /api/billing/upgrade/preview  | no Authorization header                 |
      | POST   | /api/billing/upgrade          | Bearer token "tpg@example.com"          |

  @AC-4
  Scenario: CORS only allows the local development origins
    When a browser preflight request comes from origin "http://evil.example.com"
    Then the response does not include an Access-Control-Allow-Origin header for that origin
    When a browser preflight request comes from origin "http://localhost:5173"
    Then the response allows origin "http://localhost:5173"

  @AC-4
  Scenario: Oversized sign-in input is rejected without internal details
    When the client signs in with an email of 300 characters
    Then the response status is 422
    And the response contains no stack trace

  @AC-5
  Scenario: Existing sign-in, registration, session restore and logout still work
    When "tpg@example.com" signs in with password "password"
    Then they land on the Billing page showing plan "Standard" at "$20/month" renewing on "Oct 30, 2026"
    When they reload the page
    Then they are still signed in on the Billing page
    When they log out
    Then they are on the sign-in page
    When a new user "Nina" registers with email "nina@example.com" and password "secret123"
    Then Nina lands on the Billing page showing plan "Standard" at "$20/month" renewing on "Nov 14, 2026"

  @AC-5
  Scenario: Wrong credentials and duplicate registration are still rejected
    When the client signs in as "tpg@example.com" with password "wrong"
    Then the response status is 401 with detail "Invalid credentials"
    When the client registers with email "tpg@example.com"
    Then the response status is 400 with detail "Account already exists"
