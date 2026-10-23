Feature: Story 1.6 — Signed out on an invalid or expired session
  As a subscriber, I want to be taken back to sign-in when my session is no longer valid, so that I am never
  stuck on a broken page.
  Covers: REQ-F-04, REQ-F-15

  @AC-1
  Scenario Outline: Any 401 from a protected call signs the user out
    Given "tpg@example.com" is signed in on the Billing page
    And the server will answer <call> with 401
    When the app makes <call>
    Then the stored token and user are cleared
    And the user is on the sign-in page

    Examples:
      | call                                         |
      | GET /api/billing (page load)                 |
      | GET /api/billing/upgrade/preview (open modal) |
      | POST /api/billing/upgrade (confirm)          |

  @AC-1
  Scenario: A 401 during session restore signs the user out
    Given the browser has a stored session token that the server no longer accepts
    When the app loads and requests GET "/api/users/me"
    Then the stored token and user are cleared
    And the user is on the sign-in page

  @AC-2
  Scenario: A stale email-style token from before the upgrade feature is handled once
    Given the browser's stored token is "tpg@example.com"
    When the app loads
    Then GET "/api/users/me" is requested exactly once
    And the user is on the sign-in page with no stored token
    And no error screen is shown
