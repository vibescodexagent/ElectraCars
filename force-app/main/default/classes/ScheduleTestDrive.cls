/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : DateTimeConverter
 * Author          : Vibe X
 * Created Date    : Apr 26, 2026
 * Last Modified By: Vibe X
 * Last Modified On: Apr 26, 2026
 * Description     : This class implements for Convert DateTime
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 26, 2026  │ Vibe X   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
public with sharing class ScheduleTestDrive implements Database.AllowsCallouts {

    @InvocableMethod(label='Schedule Vehicle Test Drive')
    public static List<String> Timedetails(List<TestDriveRequest> requests){

        Set<Id> serviceResourceIdSet = new Set<Id>();
        List<String> srlst = new List<String>();


        TimeZone userTZ = UserInfo.getTimeZone();
        Integer adjustedOffsetMs = userTZ.getOffset(requests[0].preferedStartTime);
        DateTime scheduleStartTime  = requests[0].preferedStartTime.addSeconds(adjustedOffsetMs / 1000);

        String vehicle = requests[0].vehicleName;
        if(!String.isBlank(vehicle)){
            vehicle = '%' + vehicle + '%';
            for(ServiceResource srAst : [SELECT Id FROM ServiceResource WHERE ResourceType='S' AND Asset.Name LIKE :vehicle LIMIT 1 ]){
                srlst.add(srAst.Id);
            }
        }

        String serviceTerritoryId = requests[0].serviceTerritoryId;

        // Territory members
        for(ServiceTerritoryMember stm : [ SELECT ServiceResourceId FROM ServiceTerritoryMember 
                                          WHERE ServiceResource.ResourceType != 'S' AND ServiceTerritoryId = :serviceTerritoryId
        ]){
            serviceResourceIdSet.add(stm.ServiceResourceId);
        }

        String skillId = [SELECT Id FROM Skill WHERE MasterLabel = 'Test Drive Assistance Skills' LIMIT 1 ].Id;
        
        Map<Id, Decimal> skillMap = new Map<Id, Decimal>();

        for(ServiceResourceSkill srs : [
            SELECT ServiceResourceId , SkillLevel
            FROM ServiceResourceSkill 
            WHERE ServiceResourceId IN :serviceResourceIdSet
            AND SkillId = :skillId 
            ORDER BY SkillLevel
        ]){
            skillMap.put(srs.ServiceResourceId, srs.SkillLevel);
            srlst.add(srs.ServiceResourceId);
        }

        GetSlotRequest slotReq = new GetSlotRequest();
        slotReq.territoryIds = new List<String>{serviceTerritoryId};
        slotReq.filterByResources = srlst;
        slotReq.startTime = scheduleStartTime;
        slotReq.endTime = scheduleStartTime.addDays(4);

        slotReq.workTypeGroupId = [SELECT Id FROM WorkTypeGroup WHERE Name = 'Test Drive' LIMIT 1].Id;

        String response = getAppointmentCandidates(slotReq);
        system.debug('response'+response);
        //return new List<String>{response};


        Object raw = JSON.deserializeUntyped(response);

        List<Object> candidates;

        if (raw instanceof Map<String, Object>) {
            Map<String, Object> result = (Map<String, Object>) raw;
            candidates = (List<Object>) result.get('candidates');
        } 
        else if (raw instanceof List<Object>) {
            candidates = (List<Object>) raw;
        } 
        else {
            return new List<String>{'No slots available'};
        }

        if (candidates == null || candidates.isEmpty()) {
            return new List<String>{'No slots available'};
        }
        
        List<Map<String, Object>> finalList = new List<Map<String, Object>>();
       
        String timeZoneId = UserInfo.getTimeZone().getID();
        Id resId;
        String resourceId;
        String startTime;
        DateTime utcStartTime;
        String endTime;
        DateTime utcEndTime;
        for (Object obj : candidates) {

            Map<String, Object> slot = (Map<String, Object>) obj;
            List<Object> resource = (List<Object>) slot.get('resources');
            resId = null;
            resourceId = null;
            startTime = (String) slot.get('startTime');
            endTime = (String) slot.get('endTime');
            utcStartTime = (Datetime)JSON.deserialize('"' + startTime + '"', Datetime.class);
            utcEndTime = (Datetime)JSON.deserialize('"' + endTime + '"', Datetime.class);
            slot.remove('startTime');
            slot.remove('endTime');
            slot.put('startTime',utcStartTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX', timeZoneId));
            slot.put('endTime',utcEndTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX', timeZoneId));
            if(resource!=null && !resource.isEmpty()){
                resourceId = (String) resource[0];
                try{
                resId = (Id)((String) resource[0]);
                }catch( Exception e){
                    System.debug('Invalid id');
                }
            }
            
            Decimal skillLevel;
            String skillType;
            
            if(resId != null && skillMap.containsKey(resId)){
                skillLevel = skillMap.get(resId);
                skillType = 'resource';
            }
            else{
                skillLevel = 100;
                skillType = 'asset';
            }
            slot.remove('resources');
            slot.put('resource',resourceId);
            
            slot.put('skillLevel', skillLevel);
            slot.put('skillType',skillType);
            finalList.add(slot);
        }
		system.debug('final'+finalList);
        return new List<String>{JSON.serialize(finalList)};
    }

    public class TestDriveRequest {       
        @InvocableVariable
        public DateTime preferedStartTime;

        @InvocableVariable
        public String vehicleName;

        @InvocableVariable
        public String serviceTerritoryId;    
    }

    public class GetSlotRequest{
        public List<String> territoryIds;
        public DateTime startTime;	
        public DateTime endTime;
        public List<String> filterByResources;
        public String workTypeGroupId;
    }

    public static String getAppointmentCandidates(GetSlotRequest slotReq){
        
        HttpCalloutService callout = new HttpCalloutService('TimeSlot');
        callout.setHeaderParameter('Content-Type','application/json');
        callout.setRequestBody(JSON.serialize(slotReq));
        system.debug('API Request: '+JSON.serialize(slotReq));
        HttpResponse res = callout.sendRequest();
        System.debug('API Response: ' + res.getBody());

        return res.getBody();
    }
}