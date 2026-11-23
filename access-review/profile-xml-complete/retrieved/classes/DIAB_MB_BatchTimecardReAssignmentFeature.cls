global class DIAB_MB_BatchTimecardReAssignmentFeature implements Database.Batchable<SObject>, Database.Stateful {
    
    // Store failed Timecard Ids
     @TestVisible
    private Set<Id> failedTimecardIds = new Set<Id>();
    @TestVisible
    private Map<Id, String> failureMessages = new Map<Id, String>();

    global Set<Id> timecardHeaderIds;

    global DIAB_MB_BatchTimecardReAssignmentFeature() {
        timecardHeaderIds = new Set<Id>();
        for (pse__Timecard_Header__c tc : [
            SELECT Id 
            FROM pse__Timecard_Header__c 
            WHERE pse__Status__c = 'Submitted' 
              AND pse__Approved__c = false 
              AND pse__Submitted__c = true
        ]) {
            timecardHeaderIds.add(tc.Id);
        }
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Datetime cutoffTime = System.now().addMinutes(-15);
        return Database.getQueryLocator([
            SELECT Id, StepStatus, Comments, ActorId, Actor.Name,
                   OriginalActorId, OriginalActor.Name,
                   ProcessInstance.TargetObjectId, ProcessInstance.TargetObject.Name,
                   CreatedDate
            FROM ProcessInstanceStep
            WHERE StepStatus = 'Reassigned'
              AND ProcessInstance.TargetObjectId IN :timecardHeaderIds
              AND CreatedDate >= :cutoffTime /*LAST_N_DAYS:30*/
            
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<ProcessInstanceStep> scope) {
        Map<Id, pse__Timecard_Header__c> timecardMap = new Map<Id, pse__Timecard_Header__c>();
        Set<String> uniqueShareKeys = new Set<String>();
        List<pse__Timecard_Header__Share> sharesToInsert = new List<pse__Timecard_Header__Share>();
        
        for (ProcessInstanceStep step : scope) {
            Id approverId = step.ActorId != null ? step.ActorId : step.OriginalActorId;
            Id timecardId = step.ProcessInstance.TargetObjectId;
            Id originalApproverId = step.OriginalActorId;
            
            if (approverId != null && timecardId != null && approverId != originalApproverId) {
                timecardMap.put(timecardId, new pse__Timecard_Header__c(
                    Id = timecardId,
                    pse__Approver__c = approverId
                ));
                system.debug(timecardMap);
                String shareKey = timecardId + '-' + approverId;
                if (!uniqueShareKeys.contains(shareKey)) {
                    uniqueShareKeys.add(shareKey);
                    
                    pse__Timecard_Header__Share share = new pse__Timecard_Header__Share();
                    share.ParentId = timecardId;
                    share.UserOrGroupId = approverId;
                    share.AccessLevel = 'Read';
                    share.RowCause = Schema.pse__Timecard_Header__Share.RowCause.Manual;
                    
                    sharesToInsert.add(share);
                }
            }
        }
        
        Id jobId = bc.getJobId();
        
        if (!timecardMap.isEmpty()) {
            List<pse__Timecard_Header__c> timecardsToUpdate = new List<pse__Timecard_Header__c>(timecardMap.values());
            Database.SaveResult[] results = Database.update(timecardsToUpdate, false);
            system.debug(results);
            
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        failedTimecardIds.add(timecardsToUpdate[i].Id);
                        failureMessages.put(timecardsToUpdate[i].Id, err.getMessage());
                        System.debug('JobId ' + jobId + ' | Failed ' + timecardsToUpdate[i].Id + ' | ' + err.getMessage());
                    }
                }
            }
        }
        
        if (!sharesToInsert.isEmpty()) {
            try {
                insert sharesToInsert;
            } catch (DmlException e) {
                // If shares fail, you might also want to notify manager
                System.debug('Share insert failed in JobId ' + jobId + ': ' + e.getMessage());
            }
        }
        
    }
    
    global void finish(Database.BatchableContext bc) {
        if (!failedTimecardIds.isEmpty()) {
            // Query Project Managers for failed Timecards
            Map<String, List<String>> managerEmailToErrors = new Map<String, List<String>>();
            
            for (pse__Timecard_Header__c tc : [
                SELECT Id, pse__Project__r.pse__Project_Manager__r.Email 
                FROM pse__Timecard_Header__c
                WHERE Id IN :failedTimecardIds
            ]) {
                String email = tc.pse__Project__r.pse__Project_Manager__r.Email;
                if (String.isNotBlank(email)) {
                    if (!managerEmailToErrors.containsKey(email)) {
                        managerEmailToErrors.put(email, new List<String>());
                    }
                    managerEmailToErrors.get(email).add('Timecard ' + tc.Id + ': ' + failureMessages.get(tc.Id));
                }
            }
            
            // Send one email per manager
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            for (String emailAddr : managerEmailToErrors.keySet()) {
                Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                msg.setToAddresses(new String[]{ emailAddr });
                msg.setSubject('Batch Job Failed for Timecards');
                msg.setPlainTextBody('The following errors occurred:\n\n' + String.join(managerEmailToErrors.get(emailAddr), '\n'));
                emails.add(msg);
            }
            
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }
        }
    }
}