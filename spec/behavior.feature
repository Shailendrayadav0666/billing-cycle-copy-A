Feature: Self-Serve Premium Upgrade — cross-story journeys
  Journeys that span several stories of Epic HELIX-6852 and only become testable once those stories
  exist. Per-story behaviour lives in spec/behavior/story-<N.M>.feature and is not repeated here.

  Background:
    Given today is "Oct 15, 2026" on the server
    And the server has just started with its seed data

  @REQ-F-01 @REQ-F-03 @REQ-F-04 @REQ-F-08 @REQ-F-10 @REQ-F-12 @REQ-F-16
  Scenario: A new subscriber signs up, upgrades mid-cycle, and the upgrade survives a sign-out and sign-in
    # stories 1.1 (sessions, upgrade), 1.4 (registration from the catalogue), 1.5 (logout), 1.2 (Premium has no button)
    Given a new user "Nina" registers with email "nina@example.com"
    And Nina's billing page shows plan "Standard" at "$20/month" renewing on "Nov 14, 2026"
    When Nina upgrades to Premium from the Billing page and confirms a charge of "$20.00" for 30 days remaining
    Then Nina's billing page shows plan "Premium" at "$40/month" renewing on "Nov 14, 2026"
    When Nina logs out
    Then Nina's previous session token is rejected with 401 on "/api/billing"
    When Nina signs in again with the same email and password
    Then Nina's billing page shows plan "Premium" at "$40/month" renewing on "Nov 14, 2026"
    And no "Upgrade to Premium" button is shown

  @REQ-F-02 @REQ-F-08 @REQ-NF-01
  Scenario: Two subscribers' sessions stay isolated through an upgrade
    # stories 1.1 (Bearer sessions), 1.2 (isolation), 1.4 (catalogue copies are independent)
    Given the seeded user "tpg@example.com" is signed in with session "S1"
    And a new user "nina@example.com" is registered and signed in with session "S2"
    When session "S2" upgrades to Premium
    Then "/api/billing" with session "S2" returns plan "Premium" with "4K Ultra HD" video quality
    And "/api/billing" with session "S1" returns plan "Standard" with "Full HD (1080p)" video quality

  @REQ-F-04 @REQ-F-15 @REQ-F-03
  Scenario: A session that expires while the upgrade modal is open sends the user back to sign-in without upgrading
    # stories 1.1 (modal), 1.5 (expiry), 1.6 (global 401 handling), 1.8 (modal error handling defers 401 to sign-out)
    Given the seeded user "tpg@example.com" is signed in and has opened the upgrade modal
    And the session lifetime has passed
    When the user clicks "Confirm Upgrade"
    Then the user is taken to the sign-in page
    And the user's plan is still "Standard"
