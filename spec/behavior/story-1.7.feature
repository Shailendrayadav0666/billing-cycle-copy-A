Feature: Story 1.7 — Cancel or dismiss the upgrade modal without upgrading
  As a Standard subscriber, I want to back out of the upgrade easily with mouse or keyboard, so that I only
  upgrade when I mean to.
  Covers: REQ-F-13, REQ-NF-03

  Background:
    Given today is "Oct 15, 2026" on the server
    And "tpg@example.com" is signed in on the Billing page on plan "Standard"
    And the upgrade dialog is open showing a charge of "$10.00"

  @AC-1
  Scenario Outline: Every way of dismissing the dialog leaves the account unchanged
    When the user <dismisses> the dialog
    Then the dialog is closed
    And no POST "/api/billing/upgrade" request was sent
    And the page still shows plan "Standard" at "$20/month" with the "Upgrade to Premium" button

    Examples:
      | dismisses                  |
      | clicks "Cancel" to close   |
      | clicks the close (X) button on |
      | presses Escape on          |
      | clicks the backdrop of     |

  @AC-2
  Scenario: The dialog is exposed to assistive technology as a modal dialog
    Then the dialog has role "dialog"
    And it has aria-modal "true"
    And its accessible name is "Upgrade to Premium"

  @AC-3
  Scenario: Focus moves into the dialog, stays there, and returns on close
    Given the dialog was opened with the keyboard from the "Upgrade to Premium" button
    Then focus is on an element inside the dialog
    When the user presses Tab repeatedly
    Then focus never leaves the dialog
    When the user presses Escape
    Then focus is on the "Upgrade to Premium" button

  @AC-4
  Scenario: Reopening the dialog requests a fresh preview
    When the user clicks "Cancel"
    And the user clicks "Upgrade to Premium" again
    Then GET "/api/billing/upgrade/preview" has been requested twice
    And the dialog shows "You'll be charged $10.00 today for the 15 days remaining in your cycle."
