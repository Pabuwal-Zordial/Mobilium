/**
 * @description Unit tests for WhiteSpaceHeatMapController covering portfolio queries,
 * single-plan queries, spend updates, and opportunity creation.
 */
@IsTest
private class WhiteSpaceHeatMapControllerTest {

    @TestSetup
    static void setupTestData() {
        // Assign Admin Permission Set to running user
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'White_Space_Analysis_Admin' LIMIT 1];
        List<PermissionSetAssignment> existing = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :ps.Id
        ];
        if (existing.isEmpty()) {
            insert new PermissionSetAssignment(
                AssigneeId = UserInfo.getUserId(),
                PermissionSetId = ps.Id
            );
        }

        // Create Account
        Account testAcc = new Account(
            Name = 'Matrix Telecom Test'
        );
        insert testAcc;

        // Create Offering
        Offering__c testOff = new Offering__c(
            Name = 'Cloud Analytics',
            Offering_Code__c = 'OFF-CLD-01',
            Product_Family__c = 'Analytics',
            Active__c = true,
            Sort_Order__c = 1
        );
        insert testOff;

        // Create Account Plan
        Account_Plan__c plan = new Account_Plan__c(
            Account__c = testAcc.Id,
            Fiscal_Year__c = 'FY2027',
            Status__c = 'Draft'
        );
        insert plan;

        // Query auto-generated assessment or insert if needed
        List<White_Space_Assessment__c> assessments = [
            SELECT Id, Our_Spending__c, Competitor_Spending__c, Internal_Spending__c, Unknown_Spending__c
            FROM White_Space_Assessment__c
            WHERE Account_Plan__c = :plan.Id
        ];

        if (assessments.isEmpty()) {
            White_Space_Assessment__c wsa = new White_Space_Assessment__c(
                Account_Plan__c = plan.Id,
                Offering__c = testOff.Id,
                Our_Spending__c = 500000,
                Competitor_Spending__c = 200000,
                Internal_Spending__c = 100000,
                Unknown_Spending__c = 0
            );
            insert wsa;
        } else {
            assessments[0].Our_Spending__c = 500000;
            assessments[0].Competitor_Spending__c = 200000;
            assessments[0].Internal_Spending__c = 100000;
            assessments[0].Unknown_Spending__c = 0;
            update assessments[0];
        }
    }

    @IsTest
    static void testGetPortfolioHeatMapData() {
        Test.startTest();
        WhiteSpaceHeatMapController.HeatMapResponse response =
            WhiteSpaceHeatMapController.getHeatMapData(null, 'FY2027');
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(false, response.isSinglePlanMode, 'Should be portfolio mode');
        System.assert(response.offerings.size() > 0, 'Should return active offerings');
        System.assert(response.rows.size() > 0, 'Should return account plan rows');
        System.assertNotEquals(null, response.kpis, 'Summary KPIs should not be null');
        System.assert(response.kpis.totalCustomerSpend > 0, 'Total customer spend should be > 0');
    }

    @IsTest
    static void testGetSinglePlanHeatMapData() {
        Account_Plan__c plan = [SELECT Id FROM Account_Plan__c LIMIT 1];

        Test.startTest();
        WhiteSpaceHeatMapController.HeatMapResponse response =
            WhiteSpaceHeatMapController.getHeatMapData(plan.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(true, response.isSinglePlanMode, 'Should be single plan mode');
        System.assertEquals(1, response.rows.size(), 'Should return exactly 1 row for the plan');
        System.assert(response.rows[0].cells.size() > 0, 'Plan row should contain offering cells');
    }

    @IsTest
    static void testUpdateAssessmentSpend() {
        White_Space_Assessment__c wsa = [SELECT Id FROM White_Space_Assessment__c LIMIT 1];

        Test.startTest();
        WhiteSpaceHeatMapController.AssessmentCell updatedCell =
            WhiteSpaceHeatMapController.updateAssessmentSpend(
                wsa.Id,
                null,
                null,
                100000,
                800000,
                50000,
                0,
                'Heavy competitor spend observed'
            );
        Test.stopTest();

        System.assertNotEquals(null, updatedCell, 'Updated cell should not be null');
        System.assertEquals(100000, updatedCell.ourSpend, 'Our spend should be 100k');
        System.assertEquals(800000, updatedCell.competitorSpend, 'Competitor spend should be 800k');
        System.assertEquals('COMPETITOR_DOMINANT', updatedCell.statusBadge, 'Status should be Competitor Dominant');
    }

    @IsTest
    static void testCreateOpportunityFromAssessment() {
        White_Space_Assessment__c wsa = [SELECT Id FROM White_Space_Assessment__c LIMIT 1];

        Test.startTest();
        String oppId = WhiteSpaceHeatMapController.createOpportunityFromAssessment(
            wsa.Id,
            'Cloud Analytics Modernization Deal',
            350000,
            Date.today().addDays(60),
            'Prospecting'
        );
        Test.stopTest();

        System.assertNotEquals(null, oppId, 'Opportunity Id should not be null');
        Opportunity createdOpp = [
            SELECT Id, Name, Amount, Account_Plan__c, White_Space_Assessment__c
            FROM Opportunity
            WHERE Id = :oppId
        ];
        System.assertEquals('Cloud Analytics Modernization Deal', createdOpp.Name, 'Opp name should match');
        System.assertEquals(350000, createdOpp.Amount, 'Opp amount should match');
        System.assertNotEquals(null, createdOpp.Account_Plan__c, 'Opp should be linked to Account Plan');
        System.assertEquals(wsa.Id, createdOpp.White_Space_Assessment__c, 'Opp should be linked to Assessment');
    }
}
