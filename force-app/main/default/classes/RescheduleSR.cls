public with sharing class RescheduleSR {
    
    @InvocableMethod(label='Get Reschedule Slots')
    public static List<OutputWrapper> getSlots(List<String> inputJsonList) {
        
        Set<Id> serviceResourceIdSet = new Set<Id>();
        List<OutputWrapper> outputs = new List<OutputWrapper>();
        OutputWrapper output = new OutputWrapper();
        String result = 'No alternative sales representative is found Please contact your manager';
        
        //  Parse JSON
        List<Object> records = (List<Object>) JSON.deserializeUntyped(inputJsonList[0]);
        Map<String, Object> rec = (Map<String, Object>) records[0];
        
        String territoryName = (String) rec.get('territory');
        String currentSRId = (String) rec.get('ServiceResourceId');
        //String startTimeStr = (String) rec.get('start_time');
        String vehiclename = (String) rec.get('model_name');
        String tdNumber = (String) rec.get('testDriveNumber');
              
        
        DateTime scheduleStart; 
        String saId;
        DateTime scheduleEnd;
        Id territoryId;
        if(!String.isBlank(tdNumber)){
            for(ServiceAppointment sa : [SELECT Id,SchedStartTime,SchedEndTime,ServiceTerritoryId  FROM ServiceAppointment WHERE Subject=:tdNumber LIMIT 1]){
                scheduleStart = sa.SchedStartTime;
                territoryId = sa.ServiceTerritoryId;
                scheduleEnd = sa.SchedEndTime;
                saId = sa.Id;
            }
        }
        
        
        System.debug('scheduleStart'+scheduleStart);
        DateTime windowStart = scheduleStart.addHours(-1);
        DateTime windowEnd = scheduleEnd.addHours(1);
        system.debug('currentTime'+system.now());
        system.debug('newschedulestart'+windowStart);
        
        //  Get other Service Resources
        List<String> srList = new List<String>();
        
        // Territory members
        set<Id> srIdSet = new set<Id>();
        Map<String,User> srUserMap = new Map<String,User>();
        for(ServiceTerritoryMember stm : [SELECT ServiceResourceId FROM ServiceTerritoryMember WHERE ServiceTerritoryId = :territoryId AND ServiceResourceId !=:currentSRId AND ServiceResource.ResourceType = 'T' ]){
            
            srIdSet.add(stm.ServiceResourceId);          
        }	
        String skillId = [SELECT Id FROM Skill WHERE MasterLabel = 'Test Drive Assistance Skills' LIMIT 1 ].Id;
        
        for(ServiceResourceSkill srs : [
            SELECT ServiceResourceId , SkillLevel, ServiceResource.RelatedRecord.Id, ServiceResource.RelatedRecord.Name FROM ServiceResourceSkill
            WHERE ServiceResourceId IN :srIdSet
            AND SkillId = :skillId 
        ]){
            srList.add(srs.ServiceResourceId);
            srUserMap.put(srs.ServiceResourceId,srs.ServiceResource.RelatedRecord);
        }
        
        //  Prepare Slot Request
        ScheduleTestDrive.GetSlotRequest slotReq = new ScheduleTestDrive.GetSlotRequest();
        slotReq.territoryIds = new List<String>{(String) territoryId};
            slotReq.filterByResources = srList;
        slotReq.startTime = windowStart;
        slotReq.endTime = windowEnd;
        
        //  WorkTypeGroup 
        slotReq.workTypeGroupId = [SELECT Id FROM WorkTypeGroup WHERE Name = 'Test Drive' LIMIT 1].Id;
        
        //  Call existing method
        String response = ScheduleTestDrive.getAppointmentCandidates(slotReq);
        
        
        
        String originalSD = scheduleStart.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        System.debug('originalSD'+originalSD);
        
        Object raw = JSON.deserializeUntyped(response);
        List<Object> candidates;
        Id resourceId;
        String startTime;
        Map<String, Object> slot = null;
        List<Object> resource = null;
        
        
        if (raw instanceof Map<String, Object>) {
            Map<String, Object> resultobj = (Map<String, Object>) raw;
            candidates = (List<Object>) resultobj.get('candidates');
        } 
        else if (raw instanceof List<Object>) {
            candidates = (List<Object>) raw;
        } 
        
        for (Object obj : candidates) {  
            slot = (Map<String, Object>) obj;
            resource = (List<Object>) slot.get('resources');
            startTime = (String) slot.get('startTime'); 
            
            system.debug('--->'+startTime);
            if(startTime.equals(originalSD)){
                resourceId = (String) resource[0];
                break;
            }
            
        }
        
        if(!String.isBlank(resourceId)){
            
            AssignedResource asr = [Select Id from AssignedResource where ServiceAppointmentId = :saId and ServiceResourceId =:currentSRId Limit 1];
            delete asr;
            
            AssignedResource ar = new AssignedResource(ServiceAppointmentId = saId, ServiceResourceId = resourceId);
            insert ar;

            
            if(!srUserMap.isEmpty() && srUserMap.containsKey(resourceId)){
                ServiceAppointment sat = new ServiceAppointment(Id=saId, ownerId = srUserMap.get(resourceId).Id);
                update sat;
                result = tdNumber + ' has been rescheduled to '+ srUserMap.get(resourceId).Name;  
				output.userId = srUserMap.get(resourceId).Id;
                
            } else{
                result = tdNumber + ' has been reschedule to the next possible available sales representative.';
            }
            output.result = result;
            output.serviceappointmentId = saId;
            outputs.add(output);
        }
        
        return outputs;   
    }
    public class OutputWrapper {
        @InvocableVariable
        public String result;
        
        @InvocableVariable
        public Id userId;
        
        @InvocableVariable
        public Id serviceappointmentId;
    }
}