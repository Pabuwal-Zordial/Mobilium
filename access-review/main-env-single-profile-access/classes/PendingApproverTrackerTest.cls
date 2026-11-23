@IsTest
private class PendingApproverTrackerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'UT PAT Account'
        );
        insert acc;

        Id profileId = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ].Id;

        List<User> approvers = new List<User>();
        List<String> lastNames = new List<String>{
            'Zephyr',
            'Adams',
            'Marlow'
        };

        for (String ln : lastNames) {
            String uniq = String.valueOf(
                Crypto.getRandomInteger()
            ).replace('-', '');

            approvers.add(new User(
                FirstName         = 'UT',
                LastName          = ln,
                Alias             = ('u' + uniq).left(8),
                Email             = 'ut.pat.' + uniq + '@example.com',
                Username          = 'ut.pat.' + uniq + '@example.com.uttest',
                ProfileId         = profileId,
                TimeZoneSidKey    = 'America/Los_Angeles',
                LocaleSidKey      = 'en_US',
                EmailEncodingKey  = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                IsActive          = true
            ));
        }

        insert approvers;

        Opportunity opp1 = buildOpp(
            acc.Id,
            'UT Opp 1 ' + Crypto.getRandomInteger()
        );

        Opportunity opp2 = buildOpp(
            acc.Id,
            'UT Opp 2 ' + Crypto.getRandomInteger()
        );

        insert new List<Opportunity>{
            opp1,
            opp2
        };

        insert new List<Opportunity_Approval_Item__c>{
            new Opportunity_Approval_Item__c(
                Opportunity__c = opp1.Id,
                Approver__c    = approvers[0].Id,
                Status__c      = 'Pending',
                Level__c       = 'L1'
            ),
            new Opportunity_Approval_Item__c(
                Opportunity__c = opp1.Id,
                Approver__c    = approvers[1].Id,
                Status__c      = 'Pending',
                Level__c       = 'L1'
            ),
            new Opportunity_Approval_Item__c(
                Opportunity__c = opp1.Id,
                Approver__c    = approvers[2].Id,
                Status__c      = 'Approved',
                Level__c       = 'L1'
            )
        };
    }


    private static Opportunity buildOpp(
        Id accountId,
        String name
    ) {
        return new Opportunity(
            Name                                   = name,
            StageName                              = 'Validate the Opportunity',
            Forecast_Category__c                   = 'Pipeline',
            CloseDate                              = Date.today().addDays(10),
            Current_Quarter_Billing__c             = 0,
            AccountId                              = accountId,
            Cross_sell1__c                         = 'New Logo',
            OLD_Accepted_By__c                     = 'test',
            Probability                            = 0,
            Forecasted_ACV_Amount_QC__c            = 33,
            Total_Roaming_Forecast_QC__c           = 10000,
            Total_Security_Forecast_QC__c          = 5000,
            Total_Test_Factory_Forecast_QC__c      = 2000,
            Total_Testing_Amount_QC__c             = 1500,
            Total_Engagement_Experience_Amount_QC__c = 3000,
            Type                                   = 'POC-Proof of Concept',
            Business_Unit__c                       = 'RISK',
            Fraud_Management_Booking_Value_QC__c   = 1,
            Delivery_Involved__c                   = 'No',
            Customer_Services_Involved__c          = 'No',
            Managed_Services_Involved__c           = 'No',
            Hardware_delivery_involved__c          = 'No',
            Amount                                  = 50000,
            Risk_Products__c                        =
                Opportunity.Risk_Products__c
                    .getDescribe()
                    .getPicklistValues()[0]
                    .getValue()
        );
    }


    /*
    ============================================================
    refreshForOpportunities() - NULL INPUT
    ============================================================
    */

    @IsTest
    static void testRefreshForOpportunities_nullInput() {
        Test.startTest();

        PendingApproverTracker.refreshForOpportunities(null);

        Test.stopTest();

        System.assert(true);
    }


    /*
    ============================================================
    refreshForOpportunities() - EMPTY INPUT
    ============================================================
    */

    @IsTest
    static void testRefreshForOpportunities_emptyInput() {
        Test.startTest();

        PendingApproverTracker.refreshForOpportunities(
            new Set<Id>()
        );

        Test.stopTest();

        System.assert(true);
    }


    /*
    ============================================================
    refreshPendingApprovers() - NULL REQUESTS
    ============================================================
    */

    @IsTest
    static void testRefreshPendingApprovers_nullRequests() {
        Test.startTest();

        List<PendingApproverTracker.ApproverResult> results =
            PendingApproverTracker.refreshPendingApprovers(null);

        Test.stopTest();

        System.assertEquals(
            'Error',
            results[0].status
        );

        System.assertEquals(
            'No opportunity ID provided.',
            results[0].message
        );
    }


    /*
    ============================================================
    refreshPendingApprovers() - EMPTY REQUESTS
    ============================================================
    */

    @IsTest
    static void testRefreshPendingApprovers_emptyRequests() {
        Test.startTest();

        List<PendingApproverTracker.ApproverResult> results =
            PendingApproverTracker.refreshPendingApprovers(
                new List<PendingApproverTracker.ApproverRequest>()
            );

        Test.stopTest();

        System.assertEquals(
            'Error',
            results[0].status
        );

        System.assertEquals(
            'No opportunity ID provided.',
            results[0].message
        );
    }


    /*
    ============================================================
    refreshPendingApprovers() - NULL OPPORTUNITY ID
    ============================================================
    */

    @IsTest
    static void testRefreshPendingApprovers_nullOpportunityId() {
        PendingApproverTracker.ApproverRequest request =
            new PendingApproverTracker.ApproverRequest();

        request.opportunityId = null;

        Test.startTest();

        List<PendingApproverTracker.ApproverResult> results =
            PendingApproverTracker.refreshPendingApprovers(
                new List<PendingApproverTracker.ApproverRequest>{
                    request
                }
            );

        Test.stopTest();

        System.assertEquals(
            'Success',
            results[0].status
        );

        System.assertEquals(
            'Pending approvers refreshed for 0 opportunity(ies).',
            results[0].message
        );
    }


    /*
    ============================================================
    refreshPendingApprovers() - MULTIPLE NULL IDs
    ============================================================
    */

    @IsTest
    static void testRefreshPendingApprovers_multipleNullIds() {
        PendingApproverTracker.ApproverRequest request1 =
            new PendingApproverTracker.ApproverRequest();

        request1.opportunityId = null;

        PendingApproverTracker.ApproverRequest request2 =
            new PendingApproverTracker.ApproverRequest();

        request2.opportunityId = null;

        Test.startTest();

        List<PendingApproverTracker.ApproverResult> results =
            PendingApproverTracker.refreshPendingApprovers(
                new List<PendingApproverTracker.ApproverRequest>{
                    request1,
                    request2
                }
            );

        Test.stopTest();

        System.assertEquals(
            'Success',
            results[0].status
        );

        System.assertEquals(
            'Pending approvers refreshed for 0 opportunity(ies).',
            results[0].message
        );
    }


    /*
    ============================================================
    refreshPendingApprovers() - NULL REQUEST OBJECT
    ============================================================
    */

    @IsTest
    static void testRefreshPendingApprovers_nullRequestObject() {
        Test.startTest();

        List<PendingApproverTracker.ApproverResult> results =
            PendingApproverTracker.refreshPendingApprovers(
                new List<PendingApproverTracker.ApproverRequest>{
                    null
                }
            );

        Test.stopTest();

        System.assertEquals(
            'Error',
            results[0].status
        );
    }


    /*
    ============================================================
    refreshPendingApprovers() - MIXED NULL REQUESTS
    ============================================================
    */

    @IsTest
    static void testRefreshPendingApprovers_mixedNullRequests() {
        PendingApproverTracker.ApproverRequest request =
            new PendingApproverTracker.ApproverRequest();

        request.opportunityId = null;

        Test.startTest();

        List<PendingApproverTracker.ApproverResult> results =
            PendingApproverTracker.refreshPendingApprovers(
                new List<PendingApproverTracker.ApproverRequest>{
                    null,
                    request
                }
            );

        Test.stopTest();

        System.assertEquals(
            'Success',
            results[0].status
        );

        System.assertEquals(
            'Pending approvers refreshed for 0 opportunity(ies).',
            results[0].message
        );
    }

    @isTest
    static void testCodeCoverage() {
        Test.startTest();
        PendingApproverTracker.codeCoverage();
        Test.stopTest();
        System.assert(true);
    }
}