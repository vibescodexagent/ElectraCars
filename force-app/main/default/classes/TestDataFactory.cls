/**
 * @description Centralized test data factory for creating test records
 * Ensures consistent test data setup across all test classes
 */
@isTest
public class TestDataFactory {
    
    /**
     * @description Creates test Account records
     * @param count Number of accounts to create
     * @param doInsert Whether to insert records into database
     * @return List of Account records
     */
    public static List<Account> createAccounts(Integer count, Boolean doInsert) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i
            ));
        }
        if (doInsert) {
            insert accounts;
        }
        return accounts;
    }
    
    /**
     * @description Creates test Contact records
     * @param count Number of Contacts to create
     * @param doInsert Whether to insert records into database
     * @return List of Contact records
     */
    public static List<Contact> createContacts(Integer count, Boolean doInsert) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            contacts.add(new Contact(
                FirstName = 'Test ',LastName = 'Contact ' + i));
        }
        if (doInsert) {
            insert contacts;
        }
        return contacts;
    }
    
    /**
     * @description Creates test Asset records for vehicles
     * @param count Number of assets to create
     * @param vehicleName Name pattern for the vehicle
     * @param doInsert Whether to insert records into database
     * @return List of Asset records
     */
    public static List<Asset> createVehicleAssets(Integer count, String vehicleName, String accId, String conId, Boolean doInsert) {
        List<Asset> assets = new List<Asset>();
        Asset ast = null;
        for (Integer i = 0; i < count; i++) {
            ast = new Asset();
            ast.Name = vehicleName + ' ' + i;
            ast.AccountId = accId;
            ast.ContactId = conId;
			assets.add(ast);            
        }
        if (doInsert) {
            insert assets;
        }
        return assets;
    }
    
    /**
     * @description Creates test ServiceResource records
     * @param count Number of service resources to create
     * @param resourceType Type of resource ('S' for asset, 'T' for technician, etc.)
     * @param relatedAssetId Optional Asset Id for vehicle resources
     * @param doInsert Whether to insert records into database
     * @return List of ServiceResource records
     */
    public static List<ServiceResource> createServiceResources(Integer count, String resourceType, Id relatedAssetId, Boolean doInsert) {
        List<ServiceResource> resources = new List<ServiceResource>();
        for (Integer i = 0; i < count; i++) {
            ServiceResource sr = new ServiceResource(
                Name = 'Test Resource ' + resourceType + ' ' + i,
                ResourceType = resourceType,
                IsActive = true
            );
            if('S'.equals(resourceType)){
                sr.AssetId = relatedAssetId;
            }else {
                sr.RelatedRecordId = relatedAssetId;
            }
            resources.add(sr);
        }
        if (doInsert) {
            insert resources;
        }
        return resources;
    }
    
    /**
     * @description Creates test ServiceTerritory records
     * @param count Number of service territories to create
     * @param operatingHoursId Operating hours Id (required)
     * @param doInsert Whether to insert records into database
     * @return List of ServiceTerritory records
     */
    public static List<ServiceTerritory> createServiceTerritories(Integer count, Id operatingHoursId, Boolean doInsert) {
        List<ServiceTerritory> territories = new List<ServiceTerritory>();
        for (Integer i = 0; i < count; i++) {
            territories.add(new ServiceTerritory(
                Name = 'Test Territory ' + i,
                OperatingHoursId = operatingHoursId,
                IsActive = true
            ));
        }
        if (doInsert) {
            insert territories;
        }
        return territories;
    }
    
    /**
     * @description Creates test OperatingHours records
     * @param count Number of operating hours to create
     * @param doInsert Whether to insert records into database
     * @return List of OperatingHours records
     */
    public static List<OperatingHours> createOperatingHours(Integer count, Boolean doInsert) {
        List<OperatingHours> operatingHours = new List<OperatingHours>();
        for (Integer i = 0; i < count; i++) {
            operatingHours.add(new OperatingHours(
                Name = 'Test Operating Hours ' + i
            ));
        }
        if (doInsert) {
            insert operatingHours;
        }
        return operatingHours;
    }
    
    /**
     * @description Creates test ServiceTerritoryMember records
     * @param serviceTerritoryId Territory Id
     * @param serviceResourceIds List of resource Ids
     * @param doInsert Whether to insert records into database
     * @return List of ServiceTerritoryMember records
     */
    public static List<ServiceTerritoryMember> createServiceTerritoryMembers(Id serviceTerritoryId, List<Id> serviceResourceIds, Boolean doInsert) {
        List<ServiceTerritoryMember> members = new List<ServiceTerritoryMember>();
        for (Id resourceId : serviceResourceIds) {
            members.add(new ServiceTerritoryMember(
                ServiceTerritoryId = serviceTerritoryId,
                ServiceResourceId = resourceId,
                EffectiveStartDate = Date.today()
            ));
        }
        if (doInsert) {
            insert members;
        }
        return members;
    }
    
    /**
     * @description Creates test ServiceResourceSkill records
     * @param serviceResourceIds List of resource Ids
     * @param skillId Skill Id
     * @param skillLevel Skill level (0.00 to 10.00)
     * @param doInsert Whether to insert records into database
     * @return List of ServiceResourceSkill records
     */
    public static List<ServiceResourceSkill> createServiceResourceSkills(List<Id> serviceResourceIds, Id skillId, Decimal skillLevel, Boolean doInsert) {
        List<ServiceResourceSkill> resourceSkills = new List<ServiceResourceSkill>();
        for (Id resourceId : serviceResourceIds) {
            resourceSkills.add(new ServiceResourceSkill(
                ServiceResourceId = resourceId,
                SkillId = skillId,
                SkillLevel = skillLevel,
                EffectiveStartDate = Date.today()
            ));
        }
        if (doInsert) {
            insert resourceSkills;
        }
        return resourceSkills;
    }
    
    /**
     * @description Creates test WorkTypeGroup records
     * @param count Number of work type groups to create
     * @param groupName Name for the work type group
     * @param doInsert Whether to insert records into database
     * @return List of WorkTypeGroup records
     */
    public static List<WorkTypeGroup> createWorkTypeGroups(Integer count, String groupName, Boolean doInsert) {
        List<WorkTypeGroup> workTypeGroups = new List<WorkTypeGroup>();
        for (Integer i = 0; i < count; i++) {
            workTypeGroups.add(new WorkTypeGroup(
                Name = groupName + (count > 1 ? ' ' + i : ''),
                GroupType = 'Default'
            ));
        }
        if (doInsert) {
            insert workTypeGroups;
        }
        return workTypeGroups;
    }
    
     /**
     * @description Creates test User records
     * @param count Number of users to create
     * @param profileId Profile Id to assign to users (if null, uses Standard User profile)
     * @param doInsert Whether to insert records into database
     * @return List of User records
     */
    public static List<User> createUsers(Integer count, Id profileId, Boolean doInsert) {
        // Get Standard User profile if profileId not provided
        Id actualProfileId = profileId;
        if (actualProfileId == null) {
            actualProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
        }
        
        List<User> users = new List<User>();
        String uniqueTimestamp = String.valueOf(System.now().getTime());
        
        for (Integer i = 0; i < count; i++) {
            String uniqueUserName = 'testuser' + i + uniqueTimestamp + '@test.com';
            users.add(new User(
                FirstName = 'Test',
                LastName = 'User ' + i,
                Email = uniqueUserName,
                Username = uniqueUserName,
                Alias = ('tuser' + i).left(8),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = actualProfileId
            ));
        }
        
        if (doInsert) {
            insert users;
        }
        return users;
    }
}