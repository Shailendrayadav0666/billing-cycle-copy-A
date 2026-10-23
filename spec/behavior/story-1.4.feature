Feature: Story 1.4 — Seed and registration use the single plan catalogue
  As a new subscriber, I want my Standard plan details to come from the same plan definition the upgrade
  uses, so that plan data can never drift between sign-up and upgrade.
  Covers: REQ-F-05, REQ-F-16, REQ-NF-05, REQ-NF-07

  Background:
    Given today is "Oct 15, 2026" on the server
    And the server has just started with its seed data

  @AC-1
  Scenario: The seeded user's billing data is unchanged
    Given "tpg@example.com" is signed in
    When the client requests GET "/api/billing"
    Then the response is plan_name "Standard", price "$20/month", renew_at "Oct 30, 2026"
    And the usages are, in order, "Video quality" = "Full HD (1080p)", "Watch at the same time" = "Can watch on 2 devices at once", "Download on devices" = "Can download on 2 devices"
    And the plan perks are, in order, "Ad-free streaming" and "Spatial audio (select titles)" with title "Plan perks"

  @AC-2
  Scenario: A newly registered user gets the Standard catalogue entry renewing in 30 days
    When "nina@example.com" registers and requests GET "/api/billing"
    Then the response is plan_name "Standard", price "$20/month", renew_at "Nov 14, 2026"
    And apart from renew_at it is identical to the seeded user's billing data

  @AC-3
  Scenario: Changing one user's billing never changes the catalogue or another user
    Given "nina@example.com" is registered and signed in
    When "nina@example.com" upgrades to Premium
    Then a user registered afterwards still gets plan_name "Standard" with "Full HD (1080p)" video quality
    And "tpg@example.com" still has plan_name "Standard"

  @AC-4
  Scenario: Registering an existing email is still rejected
    When the client registers with email "tpg@example.com"
    Then the response status is 400
    And the response detail is "Account already exists"
