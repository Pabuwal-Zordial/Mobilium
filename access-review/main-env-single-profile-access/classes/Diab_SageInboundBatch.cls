public with sharing class Diab_SageInboundBatch implements Database.Stateful, Database.AllowsCallouts, Database.Batchable<Diab_SageUtil.Diab_Sage_Employee> {
    Boolean initialRun;
    String marker;
    String batchDateTime;

    public Diab_SageInboundBatch(Boolean initialRun, String marker, String batchTS) {
        System.debug('>> Diab_SageInboundBatch  -->> Constructor');
        this.initialRun = initialRun;
        this.marker = marker;
        this.batchDateTime = String.isBlank(batchTS) ? System.DateTime.now().toString() : batchTS;
    }

    public List<Diab_SageUtil.Diab_Sage_Employee> start(Database.BatchableContext batchContext) {
        System.debug('>> Diab_SageInboundBatch  -->> Start');

        if (this.initialRun && String.isNotBlank(this.marker)) {
            System.debug('Invalid parameters passed to the batch: marker cannot be set during the initial run. Please correct input parameters.');
            return new List<Diab_SageUtil.Diab_Sage_Employee>();
        }
        else {
            Diab_SageUtil apiUtil = new Diab_SageUtil();
            Diab_SageUtil.ResponseToken respToken = apiUtil.getAuthToken();

            List<Diab_SageUtil.Diab_Sage_Employee> sageEmployeesList = apiUtil.getEmployeeRecords(this.initialRun, respToken, this.marker);
            System.debug('sageEmployeesList ### ');
            System.debug(sageEmployeesList?.size());
            System.debug(sageEmployeesList);

            if (sageEmployeesList == null || sageEmployeesList?.size() == 0) {
                this.marker = '';
            }

            return sageEmployeesList;
        }
    }

    public void execute(Database.BatchableContext batchContext, List<Diab_SageUtil.Diab_Sage_Employee> sageEmployeeRecords) {
        System.debug('>> Diab_SageInboundBatch  -->> Execute');

        this.marker = Diab_SageInboundBatchHandler.processSageEmployeeRecords(sageEmployeeRecords, this.batchDateTime);
    }
    
    public void finish(Database.BatchableContext batchContext){
        System.debug('>> Diab_SageInboundBatch  -->> Finish');
        System.debug('>> this.marker  -->> ' + this.marker);
        System.debug('>> String.isNotBlank(this.marker)  -->> ' + String.isNotBlank(this.marker));

        if (String.isNotBlank(this.marker)) {
            // Call the same batch - this time with the marker parameter
            Diab_SageInboundBatch batch = new Diab_SageInboundBatch(false, this.marker, this.batchDateTime);
            String jobId = Database.executeBatch(batch, 100);
        } else {
            // Reset integrationSettings.Sage_Run_Full_Load__c every time the batch completes. 
            // If user needs to run the full load, they must check this checkbox from Custom Settings.
            Diab_Integration_Settings__c integrationSettings = Diab_Integration_Settings__c.getOrgDefaults();
            integrationSettings.Sage_Run_Full_Load__c = false;
            update integrationSettings;

            // Batch processing completed for all employees ... send an email
            String subject = 'Sage Inbound Processing Completed ('+ (string)DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('yyyy-MM-dd') +')';
            String body = '\n\nThe Sage Inbound Batch processing has been completed successfully!';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {integrationSettings.Notification_Email__c};
            mail.setToAddresses(toAddresses);
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

            for (Messaging.SendEmailResult res : results) {
                if (res.isSuccess()) {
                    System.debug('Sage Inbound Retrieval batch: Email sent successfully!');
                }
                else {
                    System.debug('Sage Inbound Retrieval batch: The following errors occurred: ' + res.getErrors());                 
                }
            }
        }
    }
}