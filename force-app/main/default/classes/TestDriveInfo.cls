public class TestDriveInfo {
	@AuraEnabled public String testDriveId {get; set;}
    @AuraEnabled public String subject {get; set;}
    @AuraEnabled public DateTime startTime {get; set;}
    @AuraEnabled public DateTime endTime {get; set;}
    @AuraEnabled public String showRoom {get; set;}
    @AuraEnabled public String vehicleName {get; set;}
    @AuraEnabled public String serviceTerritoryId {get; set;}
}