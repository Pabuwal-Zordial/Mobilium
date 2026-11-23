public with sharing class ItemsToApproveController {

    @AuraEnabled(cacheable=true)
    public static List<PedingForApprovalRecordWrapper> getPendingForApprovalRecords(String sObjectApiName , List<String> relatedObjectFields, String orderByFieldName){
        try {
            if (String.isBlank(sObjectApiName)) {
                throw new ItemsToApproveException('The sObject Api Name cannot be blank');
            }
            return getPendingRelatedObjectRecords(sObjectApiName, relatedObjectFields, orderByFieldName);
        } catch (Exception e) {
            throw new ItemsToApproveException(e);
        }
    }

    @AuraEnabled
    public static void processRecords(List<WorkItemAction> workItemActions){
        try {
            System.debug(workItemActions);
            List<Approval.ProcessWorkitemRequest> lstWorkItemRequest = new List<Approval.ProcessWorkitemRequest>();
            for(WorkItemAction workItemAction: workItemActions) {
                if (!workItemAction.type.equals('Approve') && !workItemAction.type.equals('Reject')) {
                    throw new ItemsToApproveException('Invalid action: ' + workItemAction.type + ' for the following work item Id: ' + workItemAction.workItemId);
                }

                Approval.ProcessWorkitemRequest objWorkItemRequest = new Approval.ProcessWorkitemRequest();
                objWorkItemRequest.setComments(workItemAction.comments);
                objWorkItemRequest.setAction(workItemAction.type);
                objWorkItemRequest.setWorkitemId(workItemAction.workItemId);
                lstWorkItemRequest.add(objWorkItemRequest);
            }
            Approval.ProcessResult[] lstProcessResult = Approval.process(lstWorkItemRequest);
        } catch (Exception e) {
            throw new ItemsToApproveException(e);
        }
    }

    private static List<PedingForApprovalRecordWrapper> getPendingRelatedObjectRecords(String sObjectApiName, List<String> relatedObjectFields, String orderByFieldName) {
        List<PedingForApprovalRecordWrapper> pedingForApprovalRecordWrappers = new List<PedingForApprovalRecordWrapper>();
        Map<Id, List<ProcessInstanceWorkItem>> processInstanceWorkItemsByTargetObjectId = getPendingProcessInstanceWorkitemsByTargetObjectId(new Set<Id> { UserInfo.getUserId() }, 'Opportunity');
        Set<Id> relatedRecordIds = processInstanceWorkItemsByTargetObjectId.KeySet();
        if (!processInstanceWorkItemsByTargetObjectId.isEmpty()) {
            String relatedObjectQuery = 'SELECT Id' + ((relatedObjectFields != null && !relatedObjectFields.isEmpty()) ? (+ ',' + String.join(relatedObjectFields, ',')) : '') +
                                        ' FROM ' + sObjectApiName +
                                        ' WHERE Id IN :relatedRecordIds '+' and '+ ' Probability!=0 ';
            if (String.isNotBlank(orderByFieldName)) {
                relatedObjectQuery += 'ORDER BY ' + String.escapeSingleQuotes(orderByFieldName) + ' DESC';
            }

            for (SObject record: Database.query(relatedObjectQuery)) {
                for (ProcessInstanceWorkItem workItem: processInstanceWorkItemsByTargetObjectId.get(record.Id)) {
                    PedingForApprovalRecordWrapper wrapper = new PedingForApprovalRecordWrapper();
                    wrapper.workItemId = workItem.Id;
                    wrapper.recordId = workItem.ProcessInstance.TargetObjectId;
                    wrapper.recordName = workItem.ProcessInstance.TargetObject.Name;
                    wrapper.relatedTo = workItem.ProcessInstance.TargetObject.Type;
                    wrapper.relatedToLabel = Schema.getGlobalDescribe().get(workItem.ProcessInstance.TargetObject.Type).getDescribe().getLabel();
                    wrapper.submittedBy = workItem.ProcessInstance.SubmittedBy.Name;
                    wrapper.submittedDate = Date.newInstance(workItem.ProcessInstance.CreatedDate.year(),workItem.ProcessInstance.CreatedDate.month(),workItem.ProcessInstance.CreatedDate.day());
                    wrapper.relatedToObjectFieldsData = record.getPopulatedFieldsAsMap();
                    pedingForApprovalRecordWrappers.add(wrapper);
                }
            }
        }

        return pedingForApprovalRecordWrappers;
    }

    private static Map<Id, List<ProcessInstanceWorkItem>> getPendingProcessInstanceWorkItemsByTargetObjectId(Set<Id> actorIds, String sObjectApiName) {
        Map<Id, List<ProcessInstanceWorkItem>> processInstanceWorkItemsByTargetObjectId = new Map<Id, List<ProcessInstanceWorkItem>>();
        for (ProcessInstanceWorkItem workItem: [SELECT Id, ProcessInstance.TargetObjectId, ProcessInstance.TargetObject.Name,
                                                    ProcessInstance.CreatedDate, ProcessInstance.TargetObject.Type, ProcessInstance.SubmittedBy.Name
                                                FROM ProcessInstanceWorkItem
                                                WHERE ProcessInstance.Status = 'Pending'
                                                AND ProcessInstance.TargetObject.Type = :sObjectApiName
                                                AND ActorId IN :actorIds]) {

            if (!processInstanceWorkItemsByTargetObjectId.containsKey(workItem.ProcessInstance.TargetObjectId)) {
                processInstanceWorkItemsByTargetObjectId.put(workItem.ProcessInstance.TargetObjectId, new List<ProcessInstanceWorkItem>());
            }
            processInstanceWorkItemsByTargetObjectId.get(workItem.ProcessInstance.TargetObjectId).add(workItem);
        }
        return processInstanceWorkItemsByTargetObjectId;
    }

    //Wrapper class to store the column values of data table
    public class PedingForApprovalRecordWrapper {
        @AuraEnabled public Id workItemId;
        @AuraEnabled public String recordId;
        @AuraEnabled public String relatedTo;
        @AuraEnabled public String relatedToLabel;
        @AuraEnabled public String recordName;
        @AuraEnabled public String submittedBy;
        @AuraEnabled public Date submittedDate;
        @AuraEnabled public Map<String, Object> relatedToObjectFieldsData;
    }

    @testVisible
    public class WorkItemAction {
        @AuraEnabled public String type {get;set;}
        @AuraEnabled public String comments {get;set;}
        @AuraEnabled public Id workItemId {get;set;}
        @AuraEnabled public Id newActorId {get;set;}
    }

    public class ItemsToApproveException extends Exception {}
}