@isTest
private class DealerLocationTest {
    
    @testSetup
    static void setup() {
        // Create test data using TestDataFactory
        
        // Create Operating Hours
        List<OperatingHours> opHours = TestDataFactory.createOperatingHours(1, true);
        
        // Create Service Territory
        List<ServiceTerritory> territories = TestDataFactory.createServiceTerritories(2, opHours[0].Id, true);
        
        // Create Account and Contact for vehicles
        List<Account> accounts = TestDataFactory.createAccounts(1, true);
        List<Contact> contacts = TestDataFactory.createContacts(1, false);
        
        // Associate Contact with Account
        contacts[0].AccountId = accounts[0].Id;
        insert contacts;
        
        // Create Vehicle Assets
        List<Asset> vehicles = TestDataFactory.createVehicleAssets(
            3, 
            'Test Vehicle', 
            accounts[0].Id, 
            contacts[0].Id, 
            true
        );
    }
    
    @isTest
    static void testDealerLocationInstantiation() {
        // Test creating a DealerLocation instance
        Test.startTest();
        
        DealerLocation location = new DealerLocation();
        location.name = 'Test Dealer Location';
        location.id = '12345';
        
        Test.stopTest();
        
        // Verify properties are set correctly
        System.assertEquals('Test Dealer Location', location.name, 'Name should be set correctly');
        System.assertEquals('12345', location.id, 'ID should be set correctly');
    }
    
    @isTest
    static void testDealerLocationWithNullValues() {
        // Test DealerLocation with null values
        Test.startTest();
        
        DealerLocation location = new DealerLocation();
        // Don't set any values
        
        Test.stopTest();
        
        // Verify default null values
        System.assertEquals(null, location.name, 'Name should be null by default');
        System.assertEquals(null, location.id, 'ID should be null by default');
    }
    
    @isTest
    static void testDealerLocationSerialization() {
        // Test JSON serialization of DealerLocation
        Test.startTest();
        
        DealerLocation location = new DealerLocation();
        location.name = 'Serialization Test Location';
        location.id = 'SER123';
        
        // Serialize to JSON
        String jsonString = JSON.serialize(location);
        
        Test.stopTest();
        
        // Verify serialization
        System.assertNotEquals(null, jsonString, 'JSON string should not be null');
        System.assert(jsonString.contains('Serialization Test Location'), 'JSON should contain location name');
        System.assert(jsonString.contains('SER123'), 'JSON should contain location ID');
    }
    
    @isTest
    static void testDealerLocationDeserialization() {
        // Test JSON deserialization to DealerLocation
        Test.startTest();
        
        String jsonString = '{"name":"Deserialization Test","id":"DES456"}';
        DealerLocation location = (DealerLocation) JSON.deserialize(jsonString, DealerLocation.class);
        
        Test.stopTest();
        
        // Verify deserialization
        System.assertNotEquals(null, location, 'Location should not be null');
        System.assertEquals('Deserialization Test', location.name, 'Name should be deserialized correctly');
        System.assertEquals('DES456', location.id, 'ID should be deserialized correctly');
    }
    
    @isTest
    static void testDealerLocationListOperations() {
        // Test creating a list of DealerLocation objects
        Test.startTest();
        
        List<DealerLocation> locations = new List<DealerLocation>();
        
        for (Integer i = 0; i < 5; i++) {
            DealerLocation location = new DealerLocation();
            location.name = 'Location ' + i;
            location.id = 'LOC' + i;
            locations.add(location);
        }
        
        Test.stopTest();
        
        // Verify list operations
        System.assertEquals(5, locations.size(), 'Should have 5 locations in list');
        System.assertEquals('Location 0', locations[0].name, 'First location name should match');
        System.assertEquals('LOC4', locations[4].id, 'Last location ID should match');
    }
    
    @isTest
    static void testDealerLocationWithServiceTerritoryData() {
        // Test using DealerLocation with actual Salesforce data from TestDataFactory
        Test.startTest();
        
        List<ServiceTerritory> territories = [SELECT Id, Name FROM ServiceTerritory LIMIT 2];
        List<DealerLocation> locations = new List<DealerLocation>();
        
        for (ServiceTerritory territory : territories) {
            DealerLocation location = new DealerLocation();
            location.id = territory.Id;
            location.name = territory.Name;
            locations.add(location);
        }
        
        Test.stopTest();
        
        // Verify data population
        System.assertEquals(2, locations.size(), 'Should have 2 locations from territories');
        for (DealerLocation loc : locations) {
            System.assertNotEquals(null, loc.id, 'Location ID should not be null');
            System.assertNotEquals(null, loc.name, 'Location name should not be null');
        }
    }
    
    @isTest
    static void testDealerLocationWithAssetData() {
        // Test using DealerLocation with Asset data
        Test.startTest();
        
        List<Asset> vehicles = [SELECT Id, Name FROM Asset LIMIT 3];
        List<DealerLocation> locations = new List<DealerLocation>();
        
        for (Asset vehicle : vehicles) {
            DealerLocation location = new DealerLocation();
            location.id = vehicle.Id;
            location.name = vehicle.Name;
            locations.add(location);
        }
        
        Test.stopTest();
        
        // Verify data population
        System.assertEquals(3, locations.size(), 'Should have 3 locations from vehicles');
        for (DealerLocation loc : locations) {
            System.assertNotEquals(null, loc.id, 'Location ID should not be null');
            System.assert(loc.name.contains('Test Vehicle'), 'Location name should contain Test Vehicle');
        }
    }
    
    @isTest
    static void testDealerLocationAuraEnabledAnnotations() {
        // Test that @AuraEnabled properties work correctly with Lightning components
        Test.startTest();
        
        DealerLocation location = new DealerLocation();
        location.name = 'Aura Test Location';
        location.id = 'AURA123';
        
        // Serialize as would be done when returning to Lightning component
        String jsonForAura = JSON.serialize(location);
        
        Test.stopTest();
        
        // Verify Aura-enabled serialization
        System.assertNotEquals(null, jsonForAura, 'Aura JSON should not be null');
        System.assert(jsonForAura.contains('name'), 'Should contain name property');
        System.assert(jsonForAura.contains('id'), 'Should contain id property');
    }
    
    @isTest
    static void testBulkDealerLocationCreation() {
        // Test bulk creation to ensure no governor limit issues
        Test.startTest();
        
        List<DealerLocation> bulkLocations = new List<DealerLocation>();
        
        for (Integer i = 0; i < 200; i++) {
            DealerLocation location = new DealerLocation();
            location.name = 'Bulk Location ' + i;
            location.id = 'BULK' + i;
            bulkLocations.add(location);
        }
        
        // Serialize all locations
        String bulkJson = JSON.serialize(bulkLocations);
        
        Test.stopTest();
        
        // Verify bulk operations
        System.assertEquals(200, bulkLocations.size(), 'Should have 200 locations');
        System.assertNotEquals(null, bulkJson, 'Bulk JSON should not be null');
    }
    
    @isTest
    static void testDealerLocationPropertyModification() {
        // Test modifying properties after instantiation
        Test.startTest();
        
        DealerLocation location = new DealerLocation();
        location.name = 'Original Name';
        location.id = 'ORIG123';
        
        // Modify properties
        location.name = 'Modified Name';
        location.id = 'MOD456';
        
        Test.stopTest();
        
        // Verify modifications
        System.assertEquals('Modified Name', location.name, 'Name should be updated');
        System.assertEquals('MOD456', location.id, 'ID should be updated');
    }
}