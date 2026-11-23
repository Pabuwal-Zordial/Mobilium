/**
 * @description Opportunity trigger for White Space Analysis.
 * 1. Before Insert/Update: Auto-links Account Plan and White Space Assessment
 *    when opportunities are created directly in standard Salesforce.
 * 2. After Insert/Update: When an opportunity is Closed Won, automatically
 *    increments Our_Spending__c and absorbs white space buckets.
 */
trigger OpportunityWhiteSpaceTrigger on Opportunity (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            OpportunityWhiteSpaceTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            OpportunityWhiteSpaceTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OpportunityWhiteSpaceTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            OpportunityWhiteSpaceTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
