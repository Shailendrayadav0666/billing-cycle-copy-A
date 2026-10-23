Feature: Story 1.10 — Upgrade success message times out and can be dismissed
  As a subscriber who just upgraded, I want the confirmation message to get out of my way, so that the
  Billing page stays clean.
  Covers: REQ-F-12, REQ-NF-03

  Background:
    Given "tpg@example.com" is signed in on the Billing page on plan "Standard"
    And the user has confirmed the upgrade and the server answered successfully

  @AC-1
  Scenario: The success message is announced politely
    Then the message "You're now on Premium! Your next full cycle bills at $40/month." is shown
    And it is inside an element with role "status" and aria-live "polite"

  @AC-2
  Scenario: The success message disappears after about 5 seconds
    When 5 seconds pass
    Then the success message is no longer shown
    And the page still shows plan "Premium"

  @AC-3
  Scenario Outline: The success message can be dismissed straight away
    When the user activates the message's "Dismiss" button with <input>
    Then the success message is no longer shown immediately

    Examples:
      | input              |
      | a mouse click      |
      | the Enter key      |

  @AC-4
  Scenario: Leaving the page clears the message timer
    When the user navigates away from the Billing page before 5 seconds pass
    And 5 seconds pass
    Then no state update is attempted on the unmounted Billing page
    And no React warning is logged
