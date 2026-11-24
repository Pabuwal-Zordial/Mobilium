@IsTest
private class SecureAgreementApprovalEngineTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'UT SAE Account');
        insert acc;

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        String uniq1 = String.valueOf(Crypto.getRandomInteger()).replace('-', '');
        String uniq2 = String.valueOf(Crypto.getRandomInteger()).replace('-', '');

        insert new List<User>{
            new User(
                FirstName = 'UT', LastName = 'SaeL1', Alias = ('u' + uniq1).left(8),
                Email = 'ut.sae.l1.' + uniq1 + '@example.com', Username = 'ut.sae.l1.' + uniq1 + '@example.com.uttest',
                ProfileId = profileId, TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', IsActive = true
            ),
            new User(
                FirstName = 'UT', LastName = 'SaeL2', Alias = ('u' + uniq2).left(8),
                Email = 'ut.sae.l2.' + uniq2 + '@example.com', Username = 'ut.sae.l2.' + uniq2 + '@example.com.uttest',
                ProfileId = profileId, TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', IsActive = true
            )
        };

        User uL1 = [SELECT Id, Email FROM User WHERE Email LIKE 'ut.sae.l1.%' LIMIT 1];
        User uL2 = [SELECT Id, Email FROM User WHERE Email LIKE 'ut.sae.l2.%' LIMIT 1];

        insert new Opportunity_Dynamic_Approvals__c(
            Name = 'UT SAE Cfg', Opportunity_Stage__c = 'Secure Agreement',
            Sales_Type__c = 'New Logo', Amount__c = 'Less than 100K',
            Sales_GM_L1__c = uL1.Email, PM_L2__c = uL2.Email
        );

        // Sub_Region__c on Opportunity is a formula (Country__r.Parent_Territory__r.Name).
        // Apex tests can't see pre-existing custom-object rows, so build a tiny territory
        // hierarchy here and point Opportunity.Country__c at the child. Country__c has a
        // lookup filter requiring the Territory to use the "Country" record type.
        Id countryRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Territory__c' AND DeveloperName = 'Country' LIMIT 1].Id;
        Territory__c parentTerr = new Territory__c(Name = 'UT SAE Parent Region');
        insert parentTerr;
        insert new Territory__c(Name = 'UT SAE Country', Parent_Territory__c = parentTerr.Id, RecordTypeId = countryRtId);
    }

    private static Opportunity buildOpp(String stageName, String salesType) {
        Account acc = [SELECT Id FROM Account WHERE Name = 'UT SAE Account' LIMIT 1];
        Opportunity opp = new Opportunity(
            Name                                      = 'UT SAE Opp ' + Crypto.getRandomInteger(),
            StageName                                  = stageName,
            Forecast_Category__c                       = 'Pipeline',
            CloseDate                                  = Date.today().addDays(10),
            Current_Quarter_Billing__c                 = 0,
            AccountId                                  = acc.Id,
            Cross_sell1__c                              = salesType,
            OLD_Accepted_By__c                          = 'test',
            Probability                                = 0,
            Forecasted_ACV_Amount_QC__c                 = 33,
            Total_Roaming_Forecast_QC__c                = 10000,
            Total_Security_Forecast_QC__c               = 5000,
            Total_Test_Factory_Forecast_QC__c           = 2000,
            Total_Testing_Amount_QC__c                  = 1500,
            Total_Engagement_Experience_Amount_QC__c    = 3000,
            Type                                        = 'POC-Proof of Concept',
            Business_Unit__c                             = 'RISK',
            Fraud_Management_Booking_Value_QC__c        = 1,
            Delivery_Involved__c                        = 'No',
            Customer_Services_Involved__c               = 'No',
            Managed_Services_Involved__c                = 'No',
            Hardware_delivery_involved__c                = 'No',
            Country__c                                    = [SELECT Id FROM Territory__c WHERE Name = 'UT SAE Country' LIMIT 1].Id,
            Amount                                       = 50000,
            Risk_Products__c                             = Opportunity.Risk_Products__c.getDescribe().getPicklistValues()[0].getValue()
        );
        // A validation rule requires Opportunity_Approval_Status__c = 'Approved' before a
        // record can sit at the Secure Agreement stage.
        if ('Secure Agreement'.equalsIgnoreCase(stageName)) {
            opp.Opportunity_Approval_Status__c = 'Approved';
        }
        return opp;
    }

    @IsTest
    static void testSubmit_emptyRequests_returnsError() {
        List<SecureAgreementApprovalEngine.ApprovalResult> res = SecureAgreementApprovalEngine.submit(
            new List<SecureAgreementApprovalEngine.ApprovalRequest>()
        );
        System.assertEquals('Error', res[0].status);
    }

    @IsTest
    static void testSubmit_wrongStage_returnsError() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        insert opp;

        SecureAgreementApprovalEngine.ApprovalRequest req = new SecureAgreementApprovalEngine.ApprovalRequest();
        req.opportunityId = opp.Id;

        List<SecureAgreementApprovalEngine.ApprovalResult> res = SecureAgreementApprovalEngine.submit(
            new List<SecureAgreementApprovalEngine.ApprovalRequest>{ req }
        );

        System.assertEquals('Error', res[0].status);
        System.assert(res[0].message.contains('Secure Agreement stage'));
    }

    @IsTest
    static void testSubmit_success() {
        Opportunity opp = buildOpp('Secure Agreement', 'New Logo');
        insert opp;

        SecureAgreementApprovalEngine.ApprovalRequest req = new SecureAgreementApprovalEngine.ApprovalRequest();
        req.opportunityId = opp.Id;

        Test.startTest();
        List<SecureAgreementApprovalEngine.ApprovalResult> res = SecureAgreementApprovalEngine.submit(
            new List<SecureAgreementApprovalEngine.ApprovalRequest>{ req }
        );
        Test.stopTest();

        System.assertEquals('Success', res[0].status);
        System.assertEquals('Approval Submitted Successfully', res[0].message);

        Opportunity updated = [SELECT Second_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Pending', updated.Second_Approval_Status__c);
    }

    @IsTest
    static void testSubmit_multipleRequests_onlyFirstIsProcessed() {
        Opportunity opp1 = buildOpp('Secure Agreement', 'New Logo');
        Opportunity opp2 = buildOpp('Secure Agreement', 'New Logo');
        insert new List<Opportunity>{ opp1, opp2 };

        SecureAgreementApprovalEngine.ApprovalRequest req1 = new SecureAgreementApprovalEngine.ApprovalRequest();
        req1.opportunityId = opp1.Id;
        SecureAgreementApprovalEngine.ApprovalRequest req2 = new SecureAgreementApprovalEngine.ApprovalRequest();
        req2.opportunityId = opp2.Id;

        Test.startTest();
        List<SecureAgreementApprovalEngine.ApprovalResult> res = SecureAgreementApprovalEngine.submit(
            new List<SecureAgreementApprovalEngine.ApprovalRequest>{ req1, req2 }
        );
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals('Success', res[0].status);
    }
}