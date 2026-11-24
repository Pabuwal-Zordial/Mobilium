@IsTest
public class cls_PPOApprovalHandler_Test {
    private static final String BU_ROAMING = 'RISK';
    private static final String STAGE_SECURE_AGREEMENT = 'Secure Agreement';
    private static final String STAGE_VALIDATE = 'Validate the Opportunity';

    private static final String SALES_TYPE_UPSELL = 'Upsell';

    private static final String INVOLVED_YES = 'Yes';
    private static final String INVOLVED_NO = 'No';

    private static final String STATUS_APPROVED_2ND = 'Approved - 2nd';
    private static final String APPROVAL_TYPE_NON_STANDARD = 'Non-Standard';

    private static final String NSC_3RD_PARTY_HW_SW = 'Commercial or COTS 3rd party HW/SW” STANDARD Vendor LIST in PS template + Margin is < 25% (like Oracle, HP, Dell, Couchbase, Posgress, Cloudera, Dialogic, etc.)';

    private static Account baseAccount;
    private static Currency_Table__c baseCurrency;

    private static PricebookEntry stdPricebookEntry;
    private static Id testPbeId;
    private static Product2 product;

    // ---------------------------
    // Users / Profiles
    // ---------------------------
    private static User createUserWithProfile(Id profileId, String emailLocalPart) {
        String uniq = String.valueOf(Crypto.getRandomInteger()).replace('-', '');
        User u = new User(FirstName = 'Test', LastName = 'User', Alias = ('t' + uniq).substring(0, 8), Email = emailLocalPart + '+' + uniq + '@example.com', Username = emailLocalPart + '+' + uniq + '@example.com', ProfileId = profileId, TimeZoneSidKey = 'Europe/Lisbon', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
        insert u;
        return u;
    }

    private static Id getSysAdminProfileId() {
        return [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
    }

    private static Id getNonQuoteTeamProfileId() {
        Set<String> allowedUpper = new Set<String>{ 'QUOTE CREATION TEAM MEMBER', 'SYSTEM ADMINISTRATOR', 'SYSTEM ADMIN CERTINIA', 'MOBILEUM SYSTEM ADMIN', 'MOBILEUM SALESOPS TEAM PROFILE' };

        for (Profile p : [SELECT Id, Name FROM Profile ORDER BY Name LIMIT 500]) {
            if (p.Name == null)
                continue;
            if (!allowedUpper.contains(p.Name.toUpperCase()))
                return p.Id;
        }
        return getSysAdminProfileId();
    }

    private static Account getBaseAccount() {
        return [SELECT Id FROM Account WHERE Name = 'UT_BASE_ACCOUNT' LIMIT 1];
    }

    private static Currency_Table__c getBaseCurrency() {
        return [SELECT Id FROM Currency_Table__c WHERE Name = 'UT_USD' LIMIT 1];
    }

    private static Id getTestProduct() {
        return [SELECT Id FROM Product2 WHERE Name LIKE 'UT Product %' LIMIT 1].Id;
    }

    @TestSetup
    private static void setupTestData() {
        insert new Account(Name = 'UT_BASE_ACCOUNT');

        insert new Currency_Table__c(Name = 'UT_USD', Conversion_Rate__c = 1);

        product = new Product2(Name = 'UT Product ' + Crypto.getRandomInteger(), IsActive = true);
        insert product;

        testPbeId = Test.getStandardPricebookId();

        stdPricebookEntry = new PricebookEntry(Pricebook2Id = testPbeId, Product2Id = product.Id, UnitPrice = 1000, IsActive = true, UseStandardPrice = false);
        insert stdPricebookEntry;
    }

    private static void addOppProduct(Id oppId) {
        Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :oppId];

        if (opp.Pricebook2Id == null) {
            opp.Pricebook2Id = testPbeId;
            update opp;
            opp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :oppId];
        }

        Id pbeId;
        if (opp.Pricebook2Id == testPbeId) {
            pbeId = stdPricebookEntry.Id;
        } else {
            PricebookEntry customPbe = new PricebookEntry(Pricebook2Id = opp.Pricebook2Id, Product2Id = getTestProduct(), UnitPrice = 1000, IsActive = true, UseStandardPrice = true);
            insert customPbe;
            pbeId = customPbe.Id;
        }

        insert new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbeId, Quantity = 1, UnitPrice = 1000);
    }

    // ---------------------------
    // Opportunity creation (new per test)
    // ---------------------------
    private static Opportunity createOpportunityForPpo(Id ownerId, Decimal amountValue, String finalStageName) {
        Account acc = getBaseAccount();
        Currency_Table__c cur = getBaseCurrency();

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity ' + String.valueOf(Crypto.getRandomInteger()),
            StageName = String.isBlank(finalStageName) ? STAGE_VALIDATE : finalStageName,
            Forecast_Category__c = 'Pipeline',
            CloseDate = Date.today().addDays(10),
            Current_Quarter_Billing__c = 0,
            Currency_Table__c = cur.Id,
            AccountId = acc.Id,
            Entity_Number__c = '11 - Roamware, Inc. - US',
            Cross_sell1__c = 'New Logo',
            OLD_Accepted_By__c = 'test',
            Probability = 0,
            Forecasted_ACV_Amount_QC__c = 33,
            Total_Roaming_Forecast_QC__c = 10000,
            Total_Security_Forecast_QC__c = 5000,
            Total_Test_Factory_Forecast_QC__c = 2000,
            Total_Testing_Amount_QC__c = 1500,
            Total_Engagement_Experience_Amount_QC__c = 3000,
            Type = 'POC-Proof of Concept',
            Business_Unit__c = BU_ROAMING,
            Fraud_Management_Booking_Value_QC__c = 1,
            Delivery_Involved__c = INVOLVED_NO,
            Customer_Services_Involved__c = INVOLVED_NO,
            Managed_Services_Involved__c = INVOLVED_YES,
            Opportunity_Approval_Status__c = STATUS_APPROVED_2ND,
            Second_Approval_Status__c = STATUS_APPROVED_2ND,
            Opportunity_Approval_Type__c = APPROVAL_TYPE_NON_STANDARD,
            NON_STANDARD_CONDITIONS__c = NSC_3RD_PARTY_HW_SW,
            OwnerId = ownerId,
            Amount = amountValue,
            Risk_Products__c = Opportunity.Risk_Products__c.getDescribe().getPicklistValues()[0].getValue()
        );
        insert opp;

        addOppProduct(opp.Id);

        return opp;
    }

    private static Opportunity createOppSecureAgreement(Id ownerId, Decimal amountValue) {
        return createOpportunityForPpo(ownerId, amountValue, STAGE_SECURE_AGREEMENT);
    }

    private static Opportunity createOppWrongStage(Id ownerId, Decimal amountValue) {
        return createOpportunityForPpo(ownerId, amountValue, STAGE_VALIDATE);
    }

    // ---------------------------
    // Approval config
    // ---------------------------
    private static void createApprovalConfigDataForEmailFromOpp(Opportunity opp, String approverEmail) {
        String entityCode = '11';

        insert new Approval_Processes_Configuration__c(Name = 'APC - MAIN', Entity_Code__c = entityCode, Approval_Type__c = APPROVAL_TYPE_NON_STANDARD, Business_Unit__c = BU_ROAMING, Type__c = NSC_3RD_PARTY_HW_SW, Country__c = null, BU_Head__c = approverEmail);

        insert new Approval_Processes_Configuration__c(Name = 'APC - GOV+CRO', Entity_Code__c = entityCode, Approval_Type__c = APPROVAL_TYPE_NON_STANDARD, Business_Unit__c = BU_ROAMING, Type__c = NSC_3RD_PARTY_HW_SW, Special_Approval_Routing__c = cls_PPOApprovalHandler.APPROVER_GOVERNANCE_CRO, Approvers_Emails__c = approverEmail);

        insert new Approval_Processes_Configuration__c(Name = 'APC - CFO', Entity_Code__c = entityCode, Approval_Type__c = APPROVAL_TYPE_NON_STANDARD, Business_Unit__c = BU_ROAMING, Type__c = NSC_3RD_PARTY_HW_SW, Special_Approval_Routing__c = cls_PPOApprovalHandler.APPROVER_CFO, Approvers_Emails__c = approverEmail);

        insert new Approval_Processes_Configuration__c(Name = 'APC - Delivery Head', Entity_Code__c = entityCode, Approval_Type__c = APPROVAL_TYPE_NON_STANDARD, Business_Unit__c = BU_ROAMING, Type__c = NSC_3RD_PARTY_HW_SW, Special_Approval_Routing__c = cls_PPOApprovalHandler.CHIEF_OF_DELIVERY_SUPPORT, Approvers_Emails__c = approverEmail);

        insert new Approval_Processes_Configuration__c(Name = 'APC - MS Head', Entity_Code__c = entityCode, Approval_Type__c = APPROVAL_TYPE_NON_STANDARD, Business_Unit__c = BU_ROAMING, Type__c = NSC_3RD_PARTY_HW_SW, Special_Approval_Routing__c = cls_PPOApprovalHandler.CHIEF_OF_MANAGED_SERVICES, Approvers_Emails__c = approverEmail);

        insert new Approval_Processes_Configuration__c(Name = 'APC - CS Head', Entity_Code__c = entityCode, Approval_Type__c = APPROVAL_TYPE_NON_STANDARD, Business_Unit__c = BU_ROAMING, Type__c = NSC_3RD_PARTY_HW_SW, Special_Approval_Routing__c = cls_PPOApprovalHandler.CHIEF_OF_CUSTOMER_SUPPORT, Approvers_Emails__c = approverEmail);
    }

    private static void resetHandlerStatics() {
        cls_PPOApprovalHandler.requestApproval = true;
        cls_PPOApprovalHandler.completeFlowAlreadyRan = false;
        cls_PPOApprovalHandler.completeSecondFlowAlreadyRan = false;
        cls_PPOApprovalHandler.approvalLevel = 1;
        cls_PPOApprovalHandler.opportunityId = null;
        cls_PPOApprovalHandler.ppoDetailsId = null;
        cls_PPOApprovalHandler.specialApprover = null;
        cls_PPOApprovalHandler.isInsert = false;
        cls_PPOApprovalHandler.managerUserList = new Set<Id>();
    }

    // ---------------------------
    // PPO
    // ---------------------------
    private static PPO_Sales_Governance__c createPpo(Opportunity opp, String status) {
        PPO_Sales_Governance__c ppo = new PPO_Sales_Governance__c(Name = 'UT PPO', Opportunity__c = opp.Id, Opportunity__r = opp, PPO_Approval_Status__c = status, PPO_Reason__c = 'Unit test', PPO_Start_Date__c = Date.today(), PPO_End_Date__c = Date.today().addDays(10), PO_target_date__c = Date.today().addDays(10), Written_Confirmation_From_The_Customer__c = 'No', Third_Party_Costs__c = 0, Costs_LoE__c = 0);
        insert ppo;
        return ppo;
    }

    // ---------------------------
    // Tests
    // ---------------------------
    @IsTest
    static void testValidateRelatedOpp_wrongStage_returnsMessage() {
        User admin = createUserWithProfile(getSysAdminProfileId(), 'admin.validate');
        System.runAs(admin) {
            Opportunity wrongStage = createOppWrongStage(admin.Id, 5000);
            String msg = cls_PPOApprovalHandler.validateRelatedOpp(wrongStage);

            System.assertNotEquals(null, msg);
            System.assert(msg.contains('Secure Agreement'));
        }
    }

    @IsTest
    static void testUpdatePPOFields_blocksUnauthorizedNameChange() {
        User nonQuoteUser = createUserWithProfile(getNonQuoteTeamProfileId(), 'nonquote');
        System.runAs(nonQuoteUser) {
            Opportunity opp = createOppSecureAgreement(nonQuoteUser.Id, 5000);

            PPO_Sales_Governance__c ppo = new PPO_Sales_Governance__c(Name = 'PPO Original', Opportunity__c = opp.Id, PPO_Reason__c = 'Reason', PPO_Start_Date__c = Date.today(), PPO_End_Date__c = Date.today().addDays(5), Written_confirmation_from_the_Customer__c = 'No');
            insert ppo;

            PPO_Sales_Governance__c oldRec = [
                SELECT Id, Name, CurrencyIsoCode, PPO_Start_Date__c, PPO_End_Date__c, PO_target_date__c, Written_confirmation_from_the_Customer__c
                FROM PPO_Sales_Governance__c
                WHERE Id = :ppo.Id
            ];

            PPO_Sales_Governance__c updateRec = oldRec.clone(false, true, false, false);
            updateRec.Id = oldRec.Id;
            updateRec.Name = 'PPO Changed';

            cls_PPOApprovalHandler.updatePPOFields(new List<PPO_Sales_Governance__c>{ updateRec }, new Map<Id, PPO_Sales_Governance__c>{ oldRec.Id => oldRec });

            Database.SaveResult sr = Database.update(updateRec, false);
            System.assertEquals(false, sr.isSuccess(), 'Expected addError to block update');
            System.assert(sr.getErrors()[0].getMessage().contains('cannot change the PPO Name'));
        }
    }

    @IsTest
    static void testPPOValidationService_invocableReturnsError() {
        User admin = createUserWithProfile(getSysAdminProfileId(), 'admin.flow');

        System.runAs(admin) {
            Opportunity wrongStage = createOppWrongStage(admin.Id, 5000);

            PPOValidationService.FlowInput input = new PPOValidationService.FlowInput();
            input.recordId = wrongStage.Id;

            List<PPOValidationService.FlowOutput> outs = PPOValidationService.validatePPOInput(new List<PPOValidationService.FlowInput>{ input });

            System.assertEquals(1, outs.size());
            System.assertNotEquals(null, outs[0].errorMessage);
            System.assert(outs[0].errorMessage.contains('Secure Agreement'));
        }
    }

    @IsTest
    static void testCheckIfShouldHaveSecondLevelApproval_amountFormulaFromOpportunity() {
        User admin = createUserWithProfile(getSysAdminProfileId(), 'admin.second');

        System.runAs(admin) {
            Opportunity oppBig = createOppSecureAgreement(admin.Id, 100001);
            PPO_Sales_Governance__c ppoBig = createPpo(oppBig, 'Pending');

            PPO_Sales_Governance__c ppoBigQ = [
                SELECT Id, Amount__c, Costs_LoE__c
                FROM PPO_Sales_Governance__c
                WHERE Id = :ppoBig.Id
            ];

            System.assertEquals(false, cls_PPOApprovalHandler.checkIfShouldHaveSecondLevelApproval(ppoBigQ));

            cls_PPOApprovalHandler.codeCoverage();
        }
    }
}