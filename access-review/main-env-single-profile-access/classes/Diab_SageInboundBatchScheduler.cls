public with sharing class Diab_SageInboundBatchScheduler implements Schedulable {
    public static Diab_Integration_Settings__c integrationSettings = Diab_Integration_Settings__c.getOrgDefaults();

    public void execute(SchedulableContext ctx) {
        Boolean initialRun = true;
        String marker = '';
        String batchTimestamp = '';
        Integer batchSize = (integrationSettings?.Sage_Batch_Size__c != null && integrationSettings?.Sage_Batch_Size__c > 0) ? (Integer)integrationSettings?.Sage_Batch_Size__c : 20;

        Database.executeBatch(new Diab_SageInboundBatch(initialRun, marker, batchTimestamp), batchSize);
    }
}