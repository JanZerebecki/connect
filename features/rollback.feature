@slow_process
Feature: Rollback registration state to system products

  Scenario: Register base system
    Given I have a system with activated base product


  Scenario: Migration targets
    When Prepare SUSEConnect client with a valid regcode
    Then I should receive the next Service Packs as online migration targets


  Scenario: Rollback can be called on activated system without an issue
    When I call the migration rollback method

    Then a file named "/etc/zypp/credentials.d/SCCcredentials" should exist
    And the file "/etc/zypp/credentials.d/SCCcredentials" should contain "SCC_"

    And zypp credentials for base should exist
    And zypp credentials for base should contain "SCC_"

    And zypper should contain a service for base product
    And zypper should contain the repositories for base product


  Scenario: Rollback can be called from console with the same outcome as called from library
    When I run `SUSEConnect --rollback`
    Then the exit status should be 0

    And the output should contain "Starting to sync system product activations to the server."
    And a file named "/etc/zypp/credentials.d/SCCcredentials" should exist
    And the file "/etc/zypp/credentials.d/SCCcredentials" should contain "SCC_"

    And zypp credentials for base should exist
    And zypp credentials for base should contain "SCC_"

    And zypper should contain a service for base product
    And zypper should contain the repositories for base product


  Scenario: Remove all registration leftovers
    Then I deregister the system
