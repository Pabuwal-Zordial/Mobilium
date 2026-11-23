@isTest(SeeAllData=true)
public with sharing class Diab_SageInboundBatchSchedulerTest {

    private class Diab_SageInboundBatchScheduler_Test implements HttpCalloutMock {
        private Integer code;
        private String status;
        private String body;
        private Map<String, String> headers;

        public Diab_SageInboundBatchScheduler_Test(Integer code, String status, String body, Map<String, String> headers) {
            this.code = code;
            this.status = status;
            this.body = body;
            this.headers = headers;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.code);
            res.setStatus(this.status);
            res.setBody(this.body);
            if (this.headers != null) {
                for (String key : this.headers.keySet()) {
                    res.setHeader(key, this.headers.get(key));
                }
            }
            return res;
        }
    }

    @isTest
    public static void sageInboundBatchSchedulerTest() {
        // Mock HTTP response for getAuthToken
        String validTokenJsonBody = '{"access_token": "mock_access_token", "token_type": "Bearer", "expires_in": 3600}';
        Diab_SageInboundBatchScheduler_Test mockTokenResponse = new Diab_SageInboundBatchScheduler_Test(200, 'OK', validTokenJsonBody, null);
        Test.setMock(HttpCalloutMock.class, mockTokenResponse);

        // Mock HTTP response for getEmployeeRecords
        String validEmployeeJsonBody = '{"data":[{"id": "1", "lastName": "Doe", "firstName": "John", "additionalFields": []}, {"id": "2", "lastName": "Smith", "firstName": "Jane", "additionalFields": []}]}';
        Diab_SageInboundBatchScheduler_Test mockEmployeeResponse = new Diab_SageInboundBatchScheduler_Test(200, 'OK', validEmployeeJsonBody, null);
        Test.setMock(HttpCalloutMock.class, mockEmployeeResponse);

        // Ensure necessary test data is created
        if ([SELECT COUNT() FROM Diab_Integration_Settings__c] == 0) {
            Diab_Integration_Settings__c setting = new Diab_Integration_Settings__c(
                Sage_Auth_Endpoint__c = 'https://example.com/auth',
                Sage_Employee_Endpoint__c = 'https://example.com/employee',
                Sage_Client_Id__c = 'client_id',
                Sage_Client_Secret__c = 'client_secret',
                Sage_Username__c = 'username',
                Sage_Password__c = 'password',
                Sage_Batch_Size__c = 10
            );
            insert setting;
        }

        // Schedule job name
        String jobName = 'Test Sage Inbound Batch Job';
        Diab_SageInboundBatchScheduler scheduledJob = new Diab_SageInboundBatchScheduler();

        // Abort existing jobs with the same name
        for (CronTrigger cron : [SELECT Id, State, TimesTriggered, NextFireTime, CronJobDetailId, CronJobDetail.Name, CronJobDetail.JobType
                                 FROM CronTrigger
                                 WHERE CronJobDetail.Name = :jobName AND CronJobDetail.JobType = '7']) {
            System.abortJob(cron.Id);
        }

        // Schedule the batch job to run at the next available time
        String cronExpression = '0 0 1 * * ?';
        System.Test.startTest();
        String jobId = System.schedule(jobName, cronExpression, scheduledJob);
        System.Test.stopTest();

        // Assertions
        System.assert(jobId != null, 'Failed to schedule job ' + jobName);
    }
}