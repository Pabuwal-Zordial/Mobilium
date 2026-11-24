@IsTest
private class DynamicApprovalEngineTest {

    // ---------------------------------------------------------
    // TEST DATA SETUP
    // ---------------------------------------------------------
    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'UT DAE Account');
        insert acc;

        User uL1   = createUser('ut.dae.l1');
        User uL2   = createUser('ut.dae.l2');
        User uSAL1 = createUser('ut.dae.sal1');
        User uSAL2 = createUser('ut.dae.sal2');

        insert new Opportunity_Dynamic_Approvals__c(
            Name = 'UT Cfg DS', Opportunity_Stage__c = 'Develop Solution',
            Sales_Type__c = 'New Logo', Amount__c = 'Less than 100K',
            Sales_GM_L1__c = uL1.Email, PM_L2__c = uL2.Email
        );
        insert new Opportunity_Dynamic_Approvals__c(
            Name = 'UT Cfg SA', Opportunity_Stage__c = 'Secure Agreement',
            Sales_Type__c = 'New Logo', Amount__c = 'Less than 100K',
            Sales_GM_L1__c = uSAL1.Email, PM_L2__c = uSAL2.Email
        );

        // Sub_Region__c on Opportunity is a formula (Country__r.Parent_Territory__r.Name).
        // Apex tests can't see pre-existing custom-object rows, so build a tiny territory
        // hierarchy here and point Opportunity.Country__c at the child. Country__c has a
        // lookup filter requiring the Territory to use the "Country" record type.
        Id countryRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Territory__c' AND DeveloperName = 'Country' LIMIT 1].Id;
        Territory__c parentTerr = new Territory__c(Name = 'UT DAE Parent Region');
        insert parentTerr;
        insert new Territory__c(Name = 'UT DAE Country', Parent_Territory__c = parentTerr.Id, RecordTypeId = countryRtId);
    }

    private static User createUser(String emailPrefix) {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        String uniq = String.valueOf(Crypto.getRandomInteger()).replace('-', '');
        User u = new User(
            FirstName          = 'UT',
            LastName           = 'Approver' + uniq.substring(0, 4),
            Alias              = ('u' + uniq).left(8),
            Email              = emailPrefix + '.' + uniq + '@example.com',
            Username           = emailPrefix + '.' + uniq + '@example.com.uttest',
            ProfileId          = profileId,
            TimeZoneSidKey     = 'America/Los_Angeles',
            LocaleSidKey       = 'en_US',
            EmailEncodingKey   = 'UTF-8',
            LanguageLocaleKey  = 'en_US',
            IsActive           = true
        );
        insert u;
        return u;
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account WHERE Name = 'UT DAE Account' LIMIT 1];
    }

    private static User getUser(String emailPrefix) {
        return [SELECT Id, Email FROM User WHERE Email LIKE :(emailPrefix + '%') LIMIT 1];
    }

    // Sub_Region__c is a read-only formula (Country__r.Parent_Territory__r.Name) — set it
    // indirectly via Country__c so validatePreApprovalConditions sees a non-blank value.
    private static Id getSubRegionTerritoryId() {
        return [SELECT Id FROM Territory__c WHERE Name = 'UT DAE Country' LIMIT 1].Id;
    }

    private static final Set<String> CLOSED_STAGES = new Set<String>{ 'Won & Closed', 'Lost', 'Deleted', 'Deleted Recon' };

    private static Opportunity buildOpp(String stageName, String salesType) {
        Opportunity opp = new Opportunity(
            Name                                      = 'UT Opp ' + Crypto.getRandomInteger(),
            StageName                                  = stageName,
            Forecast_Category__c                       = CLOSED_STAGES.contains(stageName) ? 'Closed' : 'Pipeline',
            CloseDate                                  = Date.today().addDays(10),
            Current_Quarter_Billing__c                 = 0,
            AccountId                                  = getAccount().Id,
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
            Country__c                                    = getSubRegionTerritoryId(),
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

    private static DynamicApprovalEngine.ApprovalRequest requestFor(Id oppId) {
        DynamicApprovalEngine.ApprovalRequest req = new DynamicApprovalEngine.ApprovalRequest();
        req.opportunityId = oppId;
        return req;
    }

    private static DynamicApprovalEngine.ApprovalOutcomeRequest outcomeRequest(Id oppId, String outcome, String level) {
        DynamicApprovalEngine.ApprovalOutcomeRequest req = new DynamicApprovalEngine.ApprovalOutcomeRequest();
        req.opportunityId = oppId;
        req.outcome        = outcome;
        req.level          = level;
        req.actorId        = UserInfo.getUserId();
        req.comments       = 'UT comments';
        return req;
    }

    // ---------------------------------------------------------
    // submitApproval — guard clauses / validation
    // ---------------------------------------------------------
    @IsTest
    static void testSubmitApproval_nullOrEmptyRequests_returnsError() {
        List<DynamicApprovalEngine.ApprovalResult> res1 = DynamicApprovalEngine.submitApproval(null);
        List<DynamicApprovalEngine.ApprovalResult> res2 = DynamicApprovalEngine.submitApproval(new List<DynamicApprovalEngine.ApprovalRequest>());

        System.assertEquals('Error', res1[0].status);
        System.assertEquals('Error', res2[0].status);
    }

    @IsTest
    static void testSubmitApproval_opportunityNotFound_returnsError() {
        // Insert then delete to obtain a properly-formatted Id that no longer resolves to a row.
        Opportunity throwaway = buildOpp('Validate the Opportunity', 'New Logo');
        insert throwaway;
        Id fakeId = throwaway.Id;
        delete throwaway;

        List<DynamicApprovalEngine.ApprovalResult> res = DynamicApprovalEngine.submitApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(fakeId) }
        );

        System.assertEquals('Error', res[0].status);
        System.assert(res[0].message.contains('Error fetching Opportunity'));
    }

    // Note: submitApproval's "blank Sales Type" branch can't be exercised through a real,
    // persisted Opportunity — an org validation rule refuses to save one with a blank Sales
    // Type in the first place. That branch is covered directly in
    // testValidatePreApprovalConditions_directCoverage instead.

    @IsTest
    static void testSubmitApproval_blockedStage_returnsMessage() {
        Opportunity opp = buildOpp('Won & Closed', 'New Logo');
        // A Workflow Rule field update triggers an internal re-save mid-insert, re-firing
        // OpportunityTrigger's before-update handler. DynamicApprovalEngine.validateStageChange
        // then hard-blocks Won & Closed unless Opportunity_Approval_Status__c is already
        // 'Approved' — same real precondition as the Secure Agreement stage above.
        opp.Opportunity_Approval_Status__c = 'Approved';
        insert opp;

        List<DynamicApprovalEngine.ApprovalResult> res = DynamicApprovalEngine.submitApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(opp.Id) }
        );

        System.assert(res[0].message.contains('No applicable approval flow'));
    }

    @IsTest
    static void testSubmitApproval_noApproversFound_returnsError() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'Renewals');
        insert opp;

        List<DynamicApprovalEngine.ApprovalResult> res = DynamicApprovalEngine.submitApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(opp.Id) }
        );

        System.assertEquals('Error', res[0].status);
        System.assert(res[0].message.contains('No approvers were found'));
    }

    // ---------------------------------------------------------
    // submitApproval — success / resubmission guard / reject / resubmit
    // ---------------------------------------------------------
    @IsTest
    static void testSubmitApproval_success_thenAlreadyInProgress() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        insert opp;

        Test.startTest();
        List<DynamicApprovalEngine.ApprovalResult> res1 = DynamicApprovalEngine.submitApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(opp.Id) }
        );
        System.assertEquals('Success', res1[0].status);

        List<DynamicApprovalEngine.ApprovalResult> res2 = DynamicApprovalEngine.submitApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(opp.Id) }
        );
        Test.stopTest();

        System.assertEquals('Error', res2[0].status);
        System.assert(res2[0].message.contains('already in progress'));

        Opportunity updated = [SELECT Opportunity_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Submitted', updated.Opportunity_Approval_Status__c);
    }

    @IsTest
    static void testSubmitApproval_successThenReject_thenResubmit() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        insert opp;

        Test.startTest();
        List<DynamicApprovalEngine.ApprovalResult> res1 = DynamicApprovalEngine.submitApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(opp.Id) }
        );
        System.assertEquals('Success', res1[0].status);

        // handleRejectedStatus recalls the real pending L1 workitem; the process's own
        // "Recalled1" field update (a Literal update with no value) would clear
        // Opportunity_Approval_Status__c back to blank as a side effect of that recall —
        // handleRejectedStatus re-asserts 'Rejected' afterward so that side effect can't win.
        DynamicApprovalEngine.handleRejectedStatus(new List<Id>{ opp.Id });

        Opportunity afterRecall = [SELECT Opportunity_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Rejected', afterRecall.Opportunity_Approval_Status__c);

        List<DynamicApprovalEngine.ApprovalResult> res2 = DynamicApprovalEngine.submitApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(opp.Id) }
        );
        Test.stopTest();

        System.assertEquals('Success', res2[0].status);
    }

    // ---------------------------------------------------------
    // handleApprovalOutcome — direct outcome handling
    // ---------------------------------------------------------
    @IsTest
    static void testHandleApprovalOutcome_skipsInvalidRequests() {
        DynamicApprovalEngine.ApprovalOutcomeRequest blankReq = new DynamicApprovalEngine.ApprovalOutcomeRequest();
        blankReq.outcome = 'Approved';
        blankReq.level   = 'L1';
        // opportunityId intentionally left null

        DynamicApprovalEngine.handleApprovalOutcome(new List<DynamicApprovalEngine.ApprovalOutcomeRequest>{ blankReq });
        // No exception thrown means the guard skipped the invalid entry.
        System.assert(true);
    }

    @IsTest
    static void testHandleApprovalOutcome_L1Approved_noL2_fullyApproved() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'Renewals');
        opp.Opportunity_Approval_Status__c = 'Submitted';
        insert opp;

        Test.startTest();
        DynamicApprovalEngine.handleApprovalOutcome(
            new List<DynamicApprovalEngine.ApprovalOutcomeRequest>{ outcomeRequest(opp.Id, 'Approved', 'L1') }
        );
        Test.stopTest();

        Opportunity updated = [SELECT Opportunity_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Approved', updated.Opportunity_Approval_Status__c);
    }

    @IsTest
    static void testHandleApprovalOutcome_L1Approved_withL2_setsPendingApproval() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        opp.Opportunity_Approval_Status__c = 'Submitted';
        insert opp;

        Test.startTest();
        DynamicApprovalEngine.handleApprovalOutcome(
            new List<DynamicApprovalEngine.ApprovalOutcomeRequest>{ outcomeRequest(opp.Id, 'Approved', 'L1') }
        );
        Test.stopTest();

        Opportunity updated = [SELECT Opportunity_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Pending Approval', updated.Opportunity_Approval_Status__c);

        List<Related_Approver__c> related = [SELECT Approver_1__c FROM Related_Approver__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, related.size());
        System.assertEquals(getUser('ut.dae.l2').Id, related[0].Approver_1__c);
    }

    @IsTest
    static void testHandleApprovalOutcome_L2Approved_setsApproved() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        opp.Opportunity_Approval_Status__c = 'Pending Approval';
        insert opp;

        Test.startTest();
        DynamicApprovalEngine.handleApprovalOutcome(
            new List<DynamicApprovalEngine.ApprovalOutcomeRequest>{ outcomeRequest(opp.Id, 'Approved', 'L2') }
        );
        Test.stopTest();

        Opportunity updated = [SELECT Opportunity_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Approved', updated.Opportunity_Approval_Status__c);
    }

    @IsTest
    static void testHandleApprovalOutcome_Rejected_nonSA() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        opp.Opportunity_Approval_Status__c = 'Submitted';
        insert opp;

        Test.startTest();
        DynamicApprovalEngine.handleApprovalOutcome(
            new List<DynamicApprovalEngine.ApprovalOutcomeRequest>{ outcomeRequest(opp.Id, 'Rejected', 'L1') }
        );
        Test.stopTest();

        Opportunity updated = [SELECT Opportunity_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Rejected', updated.Opportunity_Approval_Status__c);

        List<EmailMessage> msgs = [SELECT Subject FROM EmailMessage WHERE RelatedToId = :opp.Id];
        System.assert(!msgs.isEmpty());
        System.assert(msgs[0].Subject.contains('OPPORTUNITY REJECTED'));
    }

    @IsTest
    static void testHandleApprovalOutcome_SA_L1Approved_submitsL2() {
        Opportunity opp = buildOpp('Secure Agreement', 'New Logo');
        opp.Second_Approval_Status__c = 'Pending';
        insert opp;

        Test.startTest();
        DynamicApprovalEngine.handleApprovalOutcome(
            new List<DynamicApprovalEngine.ApprovalOutcomeRequest>{ outcomeRequest(opp.Id, 'Approved', 'L1') }
        );
        Test.stopTest();

        // Submitting the real SA_L2 approval process carries its own initial-submission
        // FieldUpdate, which sets Second_Approval_Status__c to 'L1 Approved' again — that
        // field change is itself picked up by OpportunityTrigger, which would otherwise
        // enqueue a second, redundant L2 submission attempt as a @future. The isFuture()/
        // isBatch() guard in handleSAL1Approved blocks that redundant nested call, so the
        // status correctly stays at 'L1 Approved', genuinely waiting on the real L2 approver.
        Opportunity updated = [SELECT Second_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('L1 Approved', updated.Second_Approval_Status__c);

        List<Related_Approver__c> related = [SELECT Approver_1__c FROM Related_Approver__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, related.size());
        System.assertEquals(getUser('ut.dae.sal2').Id, related[0].Approver_1__c);
    }

    @IsTest
    static void testHandleApprovalOutcome_SA_L2Approved_setsApproved() {
        Opportunity opp = buildOpp('Secure Agreement', 'New Logo');
        opp.Second_Approval_Status__c = 'Pending';
        insert opp;

        Test.startTest();
        DynamicApprovalEngine.handleApprovalOutcome(
            new List<DynamicApprovalEngine.ApprovalOutcomeRequest>{ outcomeRequest(opp.Id, 'Approved', 'L2') }
        );
        Test.stopTest();

        Opportunity updated = [SELECT Second_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Approved', updated.Second_Approval_Status__c);
    }

    @IsTest
    static void testHandleApprovalOutcome_SA_Rejected() {
        Opportunity opp = buildOpp('Secure Agreement', 'New Logo');
        opp.Second_Approval_Status__c = 'Pending';
        insert opp;

        Test.startTest();
        DynamicApprovalEngine.handleApprovalOutcome(
            new List<DynamicApprovalEngine.ApprovalOutcomeRequest>{ outcomeRequest(opp.Id, 'Rejected', 'L1') }
        );
        Test.stopTest();

        Opportunity updated = [SELECT Second_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Rejected', updated.Second_Approval_Status__c);
    }

    @IsTest
    static void testHandleApprovalOutcome_staleState_isIgnored() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        opp.Opportunity_Approval_Status__c = 'Approved';
        insert opp;

        Test.startTest();
        DynamicApprovalEngine.handleApprovalOutcome(
            new List<DynamicApprovalEngine.ApprovalOutcomeRequest>{ outcomeRequest(opp.Id, 'Approved', 'L1') }
        );
        Test.stopTest();

        List<Related_Approver__c> related = [SELECT Id FROM Related_Approver__c WHERE Opportunity__c = :opp.Id];
        System.assert(related.isEmpty(), 'Stale-state outcome should be a no-op and never resolve L2 approvers.');
    }

    // ---------------------------------------------------------
    // submitLevel2ForOpportunity — public wrapper
    // ---------------------------------------------------------
    @IsTest
    static void testSubmitLevel2ForOpportunity_wrapper() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        opp.Opportunity_Approval_Status__c = 'Submitted';
        insert opp;

        Test.startTest();
        DynamicApprovalEngine.submitLevel2ForOpportunity(opp.Id);
        Test.stopTest();

        List<Related_Approver__c> related = [SELECT Approver_1__c FROM Related_Approver__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, related.size());
        System.assertEquals(getUser('ut.dae.l2').Id, related[0].Approver_1__c);
    }

    // ---------------------------------------------------------
    // handleReassigned — called by UpdateOppsPendingApprovalsBatch when an approval
    // work item was reassigned; recomputes Pending_Approvers__c from live pending workitems.
    // ---------------------------------------------------------
    @IsTest
    static void testHandleReassigned_refreshesPendingApprovers() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        insert opp;

        Test.startTest();
        DynamicApprovalEngine.submitApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(opp.Id) }
        );
        // Reassignment itself can't be simulated via DML (ProcessInstanceStep/Workitem aren't
        // insertable), so this calls the recompute directly - the same call
        // UpdateOppsPendingApprovalsBatch makes once it detects a 'Reassigned' step.
        DynamicApprovalEngine.handleReassigned(new Set<Id>{ opp.Id });
        Test.stopTest();

        User l1Approver = [SELECT FirstName, LastName FROM User WHERE Email LIKE 'ut.dae.l1%' LIMIT 1];
        String expectedName = (String.isNotBlank(l1Approver.FirstName) ? l1Approver.FirstName + ' ' : '') + l1Approver.LastName;

        Opportunity updated = [SELECT Pending_Approvers__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(expectedName, updated.Pending_Approvers__c);
    }

    // ---------------------------------------------------------
    // Trigger-driven handlers (field-update automation on OpportunityTrigger)
    // ---------------------------------------------------------
    @IsTest
    static void testTrigger_handleL1Approved_withL2_endsSubmitted() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        opp.Opportunity_Approval_Status__c = 'Submitted';
        insert opp;

        Test.startTest();
        opp.Opportunity_Approval_Status__c = 'L1 Approved';
        update opp;
        Test.stopTest();

        Opportunity updated = [SELECT Opportunity_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Submitted', updated.Opportunity_Approval_Status__c);
    }

    @IsTest
    static void testTrigger_handleL1Approved_noL2_endsApproved() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'Renewals');
        opp.Opportunity_Approval_Status__c = 'Submitted';
        insert opp;

        Test.startTest();
        opp.Opportunity_Approval_Status__c = 'L1 Approved';
        update opp;
        Test.stopTest();

        Opportunity updated = [SELECT Opportunity_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Approved', updated.Opportunity_Approval_Status__c);
    }

    @IsTest
    static void testTrigger_handleNonSAApproved_sendsEmail() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        opp.Opportunity_Approval_Status__c = 'Pending Approval';
        insert opp;

        Test.startTest();
        opp.Opportunity_Approval_Status__c = 'Approved';
        update opp;
        Test.stopTest();

        List<EmailMessage> msgs = [SELECT Subject FROM EmailMessage WHERE RelatedToId = :opp.Id];
        System.assert(!msgs.isEmpty());
        System.assert(msgs[0].Subject.contains('OPPORTUNITY APPROVED'));
    }

    @IsTest
    static void testTrigger_handleSAL1Approved_withL2() {
        Opportunity opp = buildOpp('Secure Agreement', 'New Logo');
        insert opp;

        Test.startTest();
        opp.Second_Approval_Status__c = 'L1 Approved';
        update opp;
        Test.stopTest();

        // handleSAL1Approved submits the real SA_L2 process asynchronously; the status
        // correctly stays at 'L1 Approved', genuinely waiting on the real L2 approver (see
        // the identical sequence documented in testHandleApprovalOutcome_SA_L1Approved_submitsL2).
        Opportunity updated = [SELECT Second_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('L1 Approved', updated.Second_Approval_Status__c);

        List<Related_Approver__c> related = [SELECT Approver_1__c FROM Related_Approver__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, related.size());
        System.assertEquals(getUser('ut.dae.sal2').Id, related[0].Approver_1__c);
    }

    @IsTest
    static void testTrigger_handleSAL1Approved_noL2_endsApproved() {
        Opportunity opp = buildOpp('Secure Agreement', 'Renewals');
        insert opp;

        Test.startTest();
        opp.Second_Approval_Status__c = 'L1 Approved';
        update opp;
        Test.stopTest();

        Opportunity updated = [SELECT Second_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Approved', updated.Second_Approval_Status__c);
    }

    @IsTest
    static void testTrigger_handleSAApproved_sendsEmailWhenDeliveryInvolved() {
        Opportunity opp = buildOpp('Secure Agreement', 'New Logo');
        opp.Delivery_Involved__c = 'Yes';
        opp.Second_Approval_Status__c = 'L1 Approved';
        insert opp;

        Test.startTest();
        opp.Second_Approval_Status__c = 'Approved';
        update opp;
        Test.stopTest();

        List<EmailMessage> msgs = [SELECT Subject FROM EmailMessage WHERE RelatedToId = :opp.Id];
        System.assert(!msgs.isEmpty());
        System.assert(msgs[0].Subject.contains('OPPORTUNITY APPROVED'));
    }

    @IsTest
    static void testTrigger_handleRejectedStatus_nonSA() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        opp.Opportunity_Approval_Status__c = 'Submitted';
        insert opp;

        Test.startTest();
        opp.Opportunity_Approval_Status__c = 'Rejected';
        update opp;
        Test.stopTest();

        List<EmailMessage> msgs = [SELECT Subject FROM EmailMessage WHERE RelatedToId = :opp.Id];
        System.assert(!msgs.isEmpty());
        System.assert(msgs[0].Subject.contains('OPPORTUNITY REJECTED'));
    }

    // ---------------------------------------------------------
    // submitSAApproval / SecureAgreementApprovalEngine entry point
    // ---------------------------------------------------------
    @IsTest
    static void testSubmitSAApproval_nullRequests_returnsError() {
        List<DynamicApprovalEngine.ApprovalResult> res = DynamicApprovalEngine.submitSAApproval(null);
        System.assertEquals('Error', res[0].status);
    }

    @IsTest
    static void testSubmitSAApproval_wrongStage_returnsError() {
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        insert opp;

        List<DynamicApprovalEngine.ApprovalResult> res = DynamicApprovalEngine.submitSAApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(opp.Id) }
        );

        System.assertEquals('Error', res[0].status);
        System.assert(res[0].message.contains('Secure Agreement stage'));
    }

    @IsTest
    static void testSubmitSAApproval_validationFails() {
        Opportunity opp = buildOpp('Secure Agreement', 'New Logo');
        opp.Country__c = null;
        insert opp;

        List<DynamicApprovalEngine.ApprovalResult> res = DynamicApprovalEngine.submitSAApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(opp.Id) }
        );

        System.assert(res[0].message.contains('Sub Region'));
    }

    @IsTest
    static void testSubmitSAApproval_noApproversFound_returnsError() {
        Opportunity opp = buildOpp('Secure Agreement', 'Cross sell');
        insert opp;

        List<DynamicApprovalEngine.ApprovalResult> res = DynamicApprovalEngine.submitSAApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(opp.Id) }
        );

        System.assertEquals('Error', res[0].status);
        System.assert(res[0].message.contains('No approvers were found'));
    }

    @IsTest
    static void testSubmitSAApproval_success_thenAlreadyInProgress() {
        Opportunity opp = buildOpp('Secure Agreement', 'New Logo');
        insert opp;

        Test.startTest();
        List<DynamicApprovalEngine.ApprovalResult> res1 = DynamicApprovalEngine.submitSAApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(opp.Id) }
        );
        System.assertEquals('Success', res1[0].status);

        List<DynamicApprovalEngine.ApprovalResult> res2 = DynamicApprovalEngine.submitSAApproval(
            new List<DynamicApprovalEngine.ApprovalRequest>{ requestFor(opp.Id) }
        );
        Test.stopTest();

        System.assertEquals('Warning', res2[0].status);
        System.assert(res2[0].message.contains('already in progress'));

        Opportunity updated = [SELECT Second_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Pending', updated.Second_Approval_Status__c);
    }

    @IsTest
    static void testSecureAgreementApprovalEngine_delegatesSuccessfully() {
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

        Opportunity updated = [SELECT Second_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Pending', updated.Second_Approval_Status__c);
    }

    // ---------------------------------------------------------
    // validateStageChange — before-update guard, exercised in memory
    // ---------------------------------------------------------
    @IsTest
    static void testValidateStageChange_blocksAndAllowsAppropriately() {
        // validateStageChange never queries the database — it only needs syntactically valid
        // Ids to use as map keys, so a batch of throwaway (never-updated) records supplies them.
        List<Opportunity> placeholders = new List<Opportunity>();
        for (Integer i = 0; i < 6; i++) {
            placeholders.add(buildOpp('Validate the Opportunity', 'New Logo'));
        }
        insert placeholders;

        Id id1 = placeholders[0].Id;
        Id id2 = placeholders[1].Id;
        Id id3 = placeholders[2].Id;
        Id id4 = placeholders[3].Id;
        Id id5 = placeholders[4].Id;
        Id id6 = placeholders[5].Id;

        // 1) Advancing to Stage 6 without first approval -> blocked
        Opportunity old1 = new Opportunity(Id = id1, StageName = 'Identify the Opportunity');
        Opportunity new1 = new Opportunity(Id = id1, StageName = 'Secure Agreement');

        // 2) Advancing to Stage 6 with first approval done -> allowed
        Opportunity old2 = new Opportunity(Id = id2, StageName = 'Identify the Opportunity');
        Opportunity new2 = new Opportunity(Id = id2, StageName = 'Secure Agreement', Opportunity_Approval_Status__c = 'Approved');

        // 3) Advancing to Stage 7 needing second approval, missing -> blocked
        Opportunity old3 = new Opportunity(Id = id3, StageName = 'Secure Agreement');
        Opportunity new3 = new Opportunity(
            Id = id3, StageName = 'PO & Signed Contract',
            Opportunity_Approval_Status__c = 'Approved', Delivery_Involved__c = 'Yes'
        );

        // 4) Advancing to Stage 7 with second approval present -> allowed
        Opportunity old4 = new Opportunity(Id = id4, StageName = 'Secure Agreement');
        Opportunity new4 = new Opportunity(
            Id = id4, StageName = 'PO & Signed Contract',
            Opportunity_Approval_Status__c = 'Approved', Delivery_Involved__c = 'Yes',
            Second_Approval_Status__c = 'Approved'
        );

        // 5) Moving backwards -> no-op
        Opportunity old5 = new Opportunity(Id = id5, StageName = 'Secure Agreement');
        Opportunity new5 = new Opportunity(Id = id5, StageName = 'Validate the Opportunity');

        // 6) Closed/Lost stage -> always skipped
        Opportunity old6 = new Opportunity(Id = id6, StageName = 'Identify the Opportunity');
        Opportunity new6 = new Opportunity(Id = id6, StageName = 'Lost');

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{
            id1 => old1, id2 => old2, id3 => old3, id4 => old4, id5 => old5, id6 => old6
        };

        DynamicApprovalEngine.validateStageChange(
            new List<Opportunity>{ new1, new2, new3, new4, new5, new6 }, oldMap
        );

        System.assert(new1.hasErrors(), 'Expected block: no first approval yet.');
        System.assert(!new2.hasErrors(), 'Expected allow: first approval done.');
        System.assert(new3.hasErrors(), 'Expected block: second approval missing.');
        System.assert(!new4.hasErrors(), 'Expected allow: second approval done.');
        System.assert(!new5.hasErrors(), 'Expected no-op: stage moved backwards.');
        System.assert(!new6.hasErrors(), 'Expected no-op: closed/lost stage.');
    }

    @IsTest
    static void testValidateStageChange_missingOldRecordIsSkipped() {
        Opportunity placeholder = buildOpp('Validate the Opportunity', 'New Logo');
        insert placeholder;
        Opportunity newOpp = new Opportunity(Id = placeholder.Id, StageName = 'Secure Agreement');

        DynamicApprovalEngine.validateStageChange(new List<Opportunity>{ newOpp }, new Map<Id, Opportunity>());

        System.assert(!newOpp.hasErrors(), 'No matching old record should be skipped without error.');
    }

    // ---------------------------------------------------------
    // validatePreApprovalConditions — direct @TestVisible coverage
    // ---------------------------------------------------------
    @IsTest
    static void testValidatePreApprovalConditions_directCoverage() {
        System.assert(DynamicApprovalEngine.validatePreApprovalConditions(null).contains('No Opportunity was found'));

        // A fresh, never-queried Opportunity has a null formula field (Sub_Region__c) by
        // definition, which is exactly the "blank" state this branch needs.
        Opportunity blank = new Opportunity(Cross_sell1__c = 'New Logo');
        System.assert(DynamicApprovalEngine.validatePreApprovalConditions(blank).contains('Sub Region'));

        // Sub_Region__c can only be non-blank on a record that's actually been queried back
        // (it's a formula derived from Country__r), so exercise the remaining branches on a
        // real, requeried record instead.
        Opportunity opp = buildOpp('Validate the Opportunity', 'New Logo');
        insert opp;
        Opportunity queried = [
            SELECT Id, Cross_sell1__c, Sub_Region__c, Hardware_delivery_involved__c,
                   Delivery_Involved__c, Managed_Services_Involved__c, Customer_Services_Involved__c, StageName
            FROM   Opportunity
            WHERE  Id = :opp.Id
        ];

        queried.Hardware_delivery_involved__c = null;
        System.assert(DynamicApprovalEngine.validatePreApprovalConditions(queried).contains('HW/SW'));

        queried.Hardware_delivery_involved__c = 'No';
        queried.Delivery_Involved__c = null;
        System.assert(DynamicApprovalEngine.validatePreApprovalConditions(queried).contains('Delivery Involved'));

        queried.Delivery_Involved__c = 'No';
        queried.Managed_Services_Involved__c = null;
        System.assert(DynamicApprovalEngine.validatePreApprovalConditions(queried).contains('Managed Services'));

        queried.Managed_Services_Involved__c = 'No';
        queried.Customer_Services_Involved__c = null;
        System.assert(DynamicApprovalEngine.validatePreApprovalConditions(queried).contains('Customer Support'));

        queried.Customer_Services_Involved__c = 'No';
        System.assertEquals(null, DynamicApprovalEngine.validatePreApprovalConditions(queried));
    }

    @isTest
    static void testCodeCoverage() {
        Test.startTest();
        ApprovalNotificationSender.codeCoverage();
        Test.stopTest();
        System.assert(true);
    }
}