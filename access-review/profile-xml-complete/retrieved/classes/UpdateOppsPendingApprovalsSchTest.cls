@isTest
private class UpdateOppsPendingApprovalsSchTest 
{
    public static String CRON_EXP = '0 0 * * * ?'; 

    @isTest
    static void testScheduledJob() 
    {

        Test.startTest();
        String jobId = System.schedule('UpdateOppsPendingApprovalsSchTest',CRON_EXP, new UpdateOppsPendingApprovalsSch());
        Test.stopTest();
        System.assertNotEquals(jobId, null, 'Job id is null');
    }
}