@isTest
private class FindNearbyServiceTerritoriesTest {

    @TestSetup
    static void setupTestData() {
        // Use TestDataFactory to create the records needed by FindNearbyServiceTerritories
        // Create one account and related assets/users/service resources as required by service.
        List<Account> accs = TestDataFactory.createAccounts(1, true);
        Id accId = accs[0].Id;

        // Create a user to run as if needed
        List<User> users = TestDataFactory.createUsers(1, null, true);
        Id userId = users[0].Id;

        // Create an Asset (vehicle) tied to the account to satisfy potential FK requirements
        List<Asset> assets = TestDataFactory.createVehicleAssets(1, 'TestVehicle', accId, null, true);

        // Create OperatingHours and ServiceTerritory to support territory logic
        List<OperatingHours> oh = TestDataFactory.createOperatingHours(1, true);
        Id operatingHoursId = oh[0].Id;
        List<ServiceTerritory> territories = TestDataFactory.createServiceTerritories(1, operatingHoursId, true);
        Id territoryId = territories[0].Id;

        // Create ServiceResource and ServiceTerritoryMember linking resources
        List<ServiceResource> resources = TestDataFactory.createServiceResources(1, 'S', assets[0].Id, true);
        List<ServiceTerritoryMember> members = TestDataFactory.createServiceTerritoryMembers(territoryId, new List<Id>{ resources[0].Id }, true);
    }

    @isTest
    static void shouldFindNearbyServiceTerritories_BasicScenario() {
        // Given - prepare the invocable Input with JSON location containing lat/lon
        FindNearbyServiceTerritories.Input inputObj = new FindNearbyServiceTerritories.Input();
        // Build GeoInput JSON with latitude and longitude
        String geoJson = '{"latitude":12.9716,"longitude":77.5946,"city":"Bengaluru","state":"KA","country":"IN"}';
        inputObj.location = geoJson;

        List<FindNearbyServiceTerritories.Input> inputs = new List<FindNearbyServiceTerritories.Input>{ inputObj };

        // When
        Test.startTest();
        List<FindNearbyServiceTerritories.Output> outputs = FindNearbyServiceTerritories.findTerritories(inputs);
        Test.stopTest();

        // Then - outputs should be returned; territories list should be present (may be empty if no ServiceTerritory within boundary)
        System.assertNotEquals(null, outputs, 'Outputs should not be null');
        System.assertEquals(1, outputs.size(), 'One output entry expected');
        // territories is initialized to empty list when no geo or no nearby found - assert not null
        System.assertNotEquals(null, outputs[0].territories, 'Territories list should be non-null');
    }

    @isTest
    static void shouldHandleEmptyInputs_WithoutThrowing() {
        // Prepare Input with missing latitude/longitude to exercise the early-return branch
        FindNearbyServiceTerritories.Input inputObj = new FindNearbyServiceTerritories.Input();
        // Provide JSON missing latitude/longitude
        inputObj.location = '{"city":"Unknown","state":"NA"}';
        List<FindNearbyServiceTerritories.Input> inputs = new List<FindNearbyServiceTerritories.Input>{ inputObj };

        Test.startTest();
        List<FindNearbyServiceTerritories.Output> outputs = FindNearbyServiceTerritories.findTerritories(inputs);
        Test.stopTest();

        // Then - outputs should contain an entry and an empty territories list
        System.assertEquals(1, outputs.size(), 'One output expected for empty input');
        System.assertNotEquals(null, outputs[0].territories, 'Territories list should be non-null');
        System.assertEquals(0, outputs[0].territories.size(), 'Territories should be empty for missing lat/lon');
    }

    @isTest
    static void shouldReturnNearbyTerritory_WhenWithinBoundary() {
        // Create a ServiceTerritory with Latitude/Longitude matching the test geo
        List<OperatingHours> operatingHours = TestDataFactory.createOperatingHours(1, true);
        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Territory Nearby',
            Latitude = 12.9716,
            Longitude = 77.5946,
            OperatingHoursId=operatingHours[0].Id
        );
        insert st;

        // Build Input JSON matching the territory coordinates
        FindNearbyServiceTerritories.Input inputObj = new FindNearbyServiceTerritories.Input();
        inputObj.location = '{"latitude":12.9716,"longitude":77.5946,"city":"Bengaluru","state":"KA","country":"IN"}';
        List<FindNearbyServiceTerritories.Input> inputs = new List<FindNearbyServiceTerritories.Input>{ inputObj };

        // When
        Test.startTest();
        List<FindNearbyServiceTerritories.Output> outputs = FindNearbyServiceTerritories.findTerritories(inputs);
        Test.stopTest();

        // Then - the returned territories should include our inserted territory
        System.assertEquals(1, outputs.size(), 'One output entry expected');
        System.assertNotEquals(null, outputs[0].territories, 'Territories list should be non-null');
        Boolean found = false;
        for (DealerLocation dl : outputs[0].territories) {
            if (dl.id == st.Id) {
                found = true;
                break;
            }
        }
        System.assert(found, 'Inserted ServiceTerritory should be returned as nearby');
    }
}