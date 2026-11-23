@isTest
private class UpdateOppsPendingApprovalsBatchTest
{
    // ProcessInstanceStep/ProcessInstance/ProcessInstanceWorkitem aren't DML-insertable, so a
    // genuine 'Reassigned' step can't be fabricated directly via test data setup - this lets
    // execute() be called directly with an in-memory step (same technique used in
    // DIAB_MB_BatchTimecardReAssignment_TC.MockBatchContext).
    private class MockBatchContext implements Database.BatchableContext {
        public Id getJobId() { return '707000000000001AAA'; }
        public Id getChildJobId() { return null; }
    }

    private static User createDynamicApprovalUser(String emailPrefix) {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        String uniq = String.valueOf(Crypto.getRandomInteger()).replace('-', '');
        User u = new User(
            FirstName = 'UT',
            LastName = 'BatchApprover' + uniq.substring(0, 4),
            Alias = ('ub' + uniq).left(8),
            Email = emailPrefix + '.' + uniq + '@example.com',
            Username = emailPrefix + '.' + uniq + '@example.com.utbatchtest',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert u;
        return u;
    }

    @testSetup
    static void setupData() 
    {
        Profile salesUserProfile = [SELECT Id FROM Profile WHERE Name='Mobileum - Sales User'];

        // Approval_Processes_Configuration__c / Approval_Process_Approver_User_Mapping__c setup
        // removed - neither UpdateOppsPendingApprovalsBatch nor these test methods read them
        // (they're only used by cls_OpportunityApprovalHandler's legacy approver resolution),
        // and inserting them here was hitting this org's CUSTOM_SETTINGS_LIMIT_EXCEEDED cap.

        User testUser = new User();
        testUser.Alias = 'standt';
        testUser.Email = 'standarduser@mbil1212.com';
        testUser.EmailEncodingKey='UTF-8';
        testUser.LastName='SalesUserTesting1';
        testUser.LanguageLocaleKey='en_US';
        testUser.LocaleSidKey='en_US';
        testUser.ProfileId = salesUserProfile.Id;
        testUser.TimeZoneSidKey='America/Los_Angeles';
        testUser.UserName='standarduser12234@mbil1212.com';
        insert testUser;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Opportunity opportunity = new Opportunity();
        opportunity.AccountId = account.Id;
        opportunity.Name = 'Test opportunity';
        opportunity.StageName ='Propose Solution';
        opportunity.Forecast_category__c='Pipeline';
        opportunity.CloseDate = System.today();
        //opportunity.Probability_to_Close_Picklist__c = '0%';
        opportunity.Type = 'TL-Term License';
        opportunity.Opportunity_Approval_Type__c = 'Non-Standard';
        opportunity.Amount = 3000000000.00;
        opportunity.Company_Code__c = 'Mobileum Inc.';
        opportunity.Business_Unit__c = 'RISK';
        opportunity.Forecasted_ACV_Amount_QC__c = 0;
        opportunity.Total_Roaming_Forecast_QC__c = 0;
        opportunity.Current_Quarter_Billing__c = 0;
        opportunity.Cross_sell1__c = 'New Logo';
        opportunity.Probability = 0;
        opportunity.Delivery_Involved__c = 'No';
        opportunity.Customer_Services_Involved__c = 'No';
        opportunity.Managed_Services_Involved__c = 'No';
        opportunity.Hardware_delivery_involved__c = 'No';
        opportunity.Risk_Products__c = Schema.SObjectType.Opportunity.fields.Risk_Products__c.getPicklistValues()[0].getValue();
        insert opportunity;

        // Non_Standard_Approval is deactivated and no longer in use (see UpdateOppsPendingApprovalsBatch's
        // relevantDeveloperNames comment) - submit through Opportunity_Dynamic_Approvals_L1 instead, which
        // is one of the four processes actually in use and is still recognized by the same batch query.
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setComments('Submitting');
        app.setProcessDefinitionNameOrId('Opportunity_Dynamic_Approvals_L1');
        app.setObjectId(opportunity.Id);
        app.setNextApproverIds(new List<Id>{UserInfo.getUserId()});
        app.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(app);
    }

    @isTest 
    static void testUpdateOppsPendingApprovalsBatch() {
        User testUser =[SELECT ID, FirstName, LastName FROM User WHERE username = 'standarduser12234@mbil1212.com'];
        Opportunity opp1 = [SELECT Id, Pending_Approvers__c FROM Opportunity Limit 1];
        String pendingApproversPriorToBatchRun = opp1.Pending_Approvers__c;

        ProcessInstanceWorkItem pi = [SELECT Id, ActorId FROM ProcessInstanceWorkItem LIMIT 1];
        pi.ActorId = testUser.Id;
        update pi;
        
        System.debug('Process Instance Steps');
        System.debug([SELECT ProcessInstance.TargetObject.Id, ProcessInstance.ProcessDefinition.Name FROM ProcessInstanceStep]);
        Test.startTest();
            UpdateOppsPendingApprovalsBatch batchInstance = new UpdateOppsPendingApprovalsBatch();
            Id batchId = Database.executeBatch(batchInstance);
        Test.stopTest();
        
        Opportunity opp2 = [SELECT Id, Pending_Approvers__c FROM Opportunity Limit 1];
        String pendingApproversAfterBatchRun = opp2.Pending_Approvers__c;

        System.assertNotEquals(pendingApproversPriorToBatchRun, pendingApproversAfterBatchRun, 'Approvers shouln\'t be the same');
    }

    // ---------------------------------------------------------
    // A 'Reassigned' step on one of the Dynamic Approval processes (Opportunity_Dynamic_Approvals_L1/
    // L2/SA_L1/SA_L2) must route to DynamicApprovalEngine.handleReassigned, not the legacy
    // Non_Standard_Approval touch-update path.
    // ---------------------------------------------------------
    @isTest
    static void testExecute_dynamicApprovalReassignment_routesToDynamicApprovalEngine() {
        Account acc = new Account(Name = 'UT Batch DAE Account');
        insert acc;

        User l1Approver = createDynamicApprovalUser('ut.batch.dae.l1');

        insert new Opportunity_Dynamic_Approvals__c(
            Name = 'UT Batch Cfg DS', Opportunity_Stage__c = 'Develop Solution',
            Sales_Type__c = 'New Logo', Amount__c = 'Less than 100K',
            Sales_GM_L1__c = l1Approver.Email
        );

        Id countryRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Territory__c' AND DeveloperName = 'Country' LIMIT 1].Id;
        Territory__c parentTerr = new Territory__c(Name = 'UT DAE Parent'); // Sub-Region1 workflow copies this name and is capped at 25 chars
        insert parentTerr;
        Territory__c countryTerr = new Territory__c(Name = 'UT DAE Country', Parent_Territory__c = parentTerr.Id, RecordTypeId = countryRtId);
        insert countryTerr;

        Opportunity opp = new Opportunity(
            Name                                     = 'UT Batch Opp ' + Crypto.getRandomInteger(),
            StageName                                = 'Validate the Opportunity',
            Forecast_Category__c                     = 'Pipeline',
            CloseDate                                = Date.today().addDays(10),
            Current_Quarter_Billing__c               = 0,
            AccountId                                = acc.Id,
            Cross_sell1__c                            = 'New Logo',
            OLD_Accepted_By__c                        = 'test',
            Probability                              = 0,
            Forecasted_ACV_Amount_QC__c               = 33,
            Total_Roaming_Forecast_QC__c              = 10000,
            Total_Security_Forecast_QC__c             = 5000,
            Total_Test_Factory_Forecast_QC__c         = 2000,
            Total_Testing_Amount_QC__c                = 1500,
            Total_Engagement_Experience_Amount_QC__c  = 3000,
            Type                                      = 'POC-Proof of Concept',
            Business_Unit__c                           = 'RISK',
            Fraud_Management_Booking_Value_QC__c      = 1,
            Delivery_Involved__c                      = 'No',
            Customer_Services_Involved__c             = 'No',
            Managed_Services_Involved__c              = 'No',
            Hardware_delivery_involved__c              = 'No',
            Country__c                                  = countryTerr.Id,
            Amount                                     = 50000,
            Risk_Products__c                           = Opportunity.Risk_Products__c.getDescribe().getPicklistValues()[0].getValue()
        );
        insert opp;

        DynamicApprovalEngine.ApprovalRequest req = new DynamicApprovalEngine.ApprovalRequest();
        req.opportunityId = opp.Id;
        DynamicApprovalEngine.submitApproval(new List<DynamicApprovalEngine.ApprovalRequest>{ req });

        Id l1ProcessDefId = [SELECT Id FROM ProcessDefinition WHERE DeveloperName = 'Opportunity_Dynamic_Approvals_L1' LIMIT 1].Id;

        ProcessInstance fakePi = new ProcessInstance(TargetObjectId = opp.Id, ProcessDefinitionId = l1ProcessDefId);
        // execute() reads ProcessInstance.TargetObject.Id (the polymorphic relationship), not
        // TargetObjectId - on an in-memory record that relationship isn't auto-populated just by
        // setting the Id field, so it must be wired explicitly or targetId resolves to null.
        fakePi.putSObject('TargetObject', new Opportunity(Id = opp.Id));
        ProcessInstanceStep fakeStep = new ProcessInstanceStep(StepStatus = 'Reassigned');
        fakeStep.ProcessInstance = fakePi;

        UpdateOppsPendingApprovalsBatch batchInstance = new UpdateOppsPendingApprovalsBatch();
        Database.BatchableContext mockCtx = new MockBatchContext();

        Test.startTest();
        batchInstance.start(mockCtx); // resolves and caches the real Dynamic Approval process def Ids
        batchInstance.execute(mockCtx, new List<ProcessInstanceStep>{ fakeStep });
        Test.stopTest();

        String expectedName = (String.isNotBlank(l1Approver.FirstName) ? l1Approver.FirstName + ' ' : '') + l1Approver.LastName;
        Opportunity updated = [SELECT Pending_Approvers__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(expectedName, updated.Pending_Approvers__c,
            'Dynamic Approval reassignment should route through DynamicApprovalEngine.handleReassigned and recompute from the live pending workitem.');
    }
}