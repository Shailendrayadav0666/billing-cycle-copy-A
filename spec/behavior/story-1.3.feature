Feature: Story 1.3 — Proration boundary and rounding rules
  As a Standard subscriber, I want the prorated charge to be correct at the edges of my billing cycle, so
  that I am never over- or under-charged.
  Covers: REQ-F-06, REQ-NF-06

  Background:
    Given today is "Oct 15, 2026" on the server
    And a Standard user "sam@example.com" is signed in

  @AC-1
  Scenario Outline: A renewal date of today or earlier means no charge, and the upgrade still proceeds
    Given Sam's renewal date is "<renew_at>"
    When Sam previews the upgrade
    Then days_remaining is 0 and prorated_charge is 0.00
    When Sam confirms the upgrade
    Then the response status is 200 with plan_name "Premium" and prorated_charge 0.00

    Examples:
      | renew_at     |
      | Oct 15, 2026 |
      | Oct 01, 2026 |

  @AC-2
  Scenario Outline: The charge never exceeds the full price difference
    Given Sam's renewal date is "<renew_at>"
    When Sam previews the upgrade
    Then days_remaining is <days> and prorated_charge is 20.00

    Examples:
      | renew_at     | days |
      | Nov 14, 2026 | 30   |
      | Nov 29, 2026 | 45   |

  @AC-3
  Scenario Outline: The charge is rounded half up to two decimals
    Given Sam's renewal date is "<renew_at>"
    When Sam previews the upgrade
    Then days_remaining is <days> and prorated_charge is <charge>
    And the dialog shows "You'll be charged $<charge> today for the <days> days remaining in your cycle."

    Examples:
      | renew_at     | days | charge |
      | Oct 16, 2026 | 1    | 0.67   |
      | Oct 22, 2026 | 7    | 4.67   |
      | Nov 13, 2026 | 29   | 19.33  |

  @AC-4
  Scenario: The previewed charge and the applied charge are identical on the same day
    Given Sam's renewal date is "Oct 22, 2026"
    When Sam previews the upgrade and then confirms it
    Then both responses have prorated_charge 4.67
