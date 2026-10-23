Feature: Story 1.5 — Sessions expire and logout ends the session
  As a subscriber, I want my session to end when I log out or after a while, so that nobody can keep using
  my account from an old token.
  Covers: REQ-F-03, REQ-F-16, REQ-NF-01

  Background:
    Given the session lifetime is 8 hours
    And "tpg@example.com" signed in at "2026-10-15T09:00:00Z" and holds session token "S1"

  @AC-1
  Scenario: A session older than its lifetime is rejected
    Given the time is now "2026-10-15T17:00:01Z"
    When the client sends GET "/api/billing" with token "S1"
    Then the response status is 401
    And the response detail is "Not authenticated"

  @AC-1
  Scenario: A session within its lifetime is accepted
    Given the time is now "2026-10-15T16:59:59Z"
    When the client sends GET "/api/billing" with token "S1"
    Then the response status is 200

  @AC-2
  Scenario: Logout invalidates the session on the server
    When the client sends POST "/api/auth/logout" with token "S1"
    Then the response status is 200
    And GET "/api/billing" with token "S1" returns 401
    And GET "/api/users/me" with token "S1" returns 401

  @AC-3
  Scenario Outline: Logout with a missing or unknown token is refused and affects no one else
    Given "nina@example.com" holds a valid session token "S2"
    When the client sends POST "/api/auth/logout" with <credential>
    Then the response status is 401
    And GET "/api/billing" with token "S2" returns 200

    Examples:
      | credential                      |
      | no Authorization header         |
      | Bearer token "unknown-token"    |

  @AC-4
  Scenario: The Logout button ends the server session even if the call fails
    Given "tpg@example.com" is signed in on the Billing page
    When they click "Logout"
    Then the app sends POST "/api/auth/logout" with their token
    And they are on the sign-in page with no stored token
    Given the logout request fails with a network error
    When they sign in again and click "Logout"
    Then they are still on the sign-in page with no stored token

  @AC-5
  Scenario: Logout and expiry are logged without secrets
    When the client logs out with token "S1"
    Then the server log contains an INFO "logout" entry with user_id 1
    And no server log line contains "S1", "tpg@example.com" or "password"
