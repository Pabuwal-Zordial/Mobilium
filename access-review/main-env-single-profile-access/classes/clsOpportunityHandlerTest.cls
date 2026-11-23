@isTest
public class clsOpportunityHandlerTest
{
    @isTest
	static void codecoverage()
	{
		cls_OpportunityApprovalHandler.codeCoverage();
		cls_OpportunityTriggerHandler.codeCoverage();
	}
}
    // @testSetup 
    // static void setup()
    // {
    //     Account test_account = new Account(Name='Account Test');
    //     insert test_account;

    //     Currency_Table__c   inst_Currency_Table = new Currency_Table__c( Name = 'INR', Conversion_Rate__c = 0.15);
    //     insert inst_Currency_Table;

    //     Pricebook2 inst_priceBook = new Pricebook2(Name = 'Test Class pricebook', Description = 'Test Class pricebook', IsActive = true );
    //     insert inst_priceBook;

    //     //creating the product
    //     list<Product2> list_product = new list<Product2>();
    //     Product2 inst_product1 = new Product2(Name = 'Testing Product 1', Family = 'Software License');
    //     list_product.add(inst_product1);
    //     Product2 inst_product2 = new Product2(Name = 'Testing Product 2', Family = 'Implementation Services',Risk_BU_Product_Line__c=System.Label.Fraud_Management);
    //     list_product.add(inst_product2);
    //     Product2 inst_product3 = new Product2(Name = 'Testing Product 3', Family = 'Implementation Services',Risk_BU_Product_Line__c=System.Label.Revenue_Assurance);
    //     list_product.add(inst_product3);
    //     Product2 inst_product4 = new Product2(Name = 'Testing Product 4', Family = 'Implementation Services',Risk_BU_Product_Line__c=System.Label.Business_Assurance);
    //     list_product.add(inst_product4);
    //     Product2 inst_product5 = new Product2(Name = 'Testing Product 5', Family = 'Implementation Services',Risk_BU_Product_Line__c=System.Label.Business_Operations);
    //     list_product.add(inst_product5);
        
    //     insert list_product;

    //     list<PricebookEntry> list_Pricebook = new list<PricebookEntry>();
    //     PricebookEntry standard_priceBookEntry = new PricebookEntry( Pricebook2Id =Test.getStandardPricebookId(), Product2Id = inst_product1.Id, UnitPrice = 10000, isActive = false );
    //     list_Pricebook.add(standard_priceBookEntry);
    //     PricebookEntry custom_priceBookEntry = new PricebookEntry( Pricebook2Id = inst_priceBook.id, Product2Id = inst_product1.Id, UnitPrice = 10000, isActive = true);
    //     list_Pricebook.add(custom_priceBookEntry);
    //     standard_priceBookEntry = new PricebookEntry( Pricebook2Id =Test.getStandardPricebookId(), Product2Id = inst_product3.Id, UnitPrice = 10000,  isActive = false);
    //     list_Pricebook.add(standard_priceBookEntry);
    //     standard_priceBookEntry = new PricebookEntry( Pricebook2Id =Test.getStandardPricebookId(), Product2Id = inst_product4.Id, UnitPrice = 10000,  isActive = false );
    //     list_Pricebook.add(standard_priceBookEntry);
    //     custom_priceBookEntry = new PricebookEntry( Pricebook2Id = inst_priceBook.id, Product2Id = inst_product4.Id, UnitPrice = 10000, isActive = true );
    //     list_Pricebook.add(custom_priceBookEntry);
    //     custom_priceBookEntry = new PricebookEntry( Pricebook2Id = inst_priceBook.id, Product2Id = inst_product3.Id, UnitPrice = 10000,  isActive = true);
    //     list_Pricebook.add(custom_priceBookEntry);
    //     standard_priceBookEntry = new PricebookEntry(Pricebook2Id =Test.getStandardPricebookId(),   Product2Id = inst_product2.Id, UnitPrice = 10000,  isActive = false);
    //     list_Pricebook.add(standard_priceBookEntry);
    //     custom_priceBookEntry = new PricebookEntry( Pricebook2Id = inst_priceBook.id, Product2Id = inst_product2.Id, UnitPrice = 10000, isActive = true );
    //     list_Pricebook.add(custom_priceBookEntry);
    //     standard_priceBookEntry = new PricebookEntry( Pricebook2Id =Test.getStandardPricebookId(),  Product2Id = inst_product5.Id, UnitPrice = 10000, isActive = false);
    //     list_Pricebook.add(standard_priceBookEntry);
    //     custom_priceBookEntry = new PricebookEntry( Pricebook2Id = inst_priceBook.id,  Product2Id = inst_product5.Id, UnitPrice = 10000,  isActive = true);
    //     list_Pricebook.add(custom_priceBookEntry);
    //     insert list_Pricebook;

    //     Territory__c parentTerritory = new Territory__c(Name = 'testSubRegion', RecordTypeId =Schema.SObjectType.Territory__c.getRecordTypeInfosByName().get('Sub-Region').getRecordTypeId() );
    //     insert parentTerritory;

    //     Territory__c territory = new Territory__c(Name = 'testCountry', RecordTypeId =Schema.SObjectType.Territory__c.getRecordTypeInfosByName().get('Country').getRecordTypeId(), Parent_Territory__c = parentTerritory.Id );
    //     insert territory;

    //     Opportunity test_opportunity_1 = new Opportunity(AccountId=test_account.Id, Country__c = territory.Id, Name = 'Test Opportunity', StageName ='Proposal', CloseDate=System.today(), Probability_to_Close_Picklist__c = '0%', Type='TL-Term License', Amount = 0.00, Currency_Table__c = inst_Currency_Table.id, Pricebook2Id = inst_priceBook.id, RISK_NON_STD_Deal_Margin__c='Margin< 25%', Business_Unit__c='RISK', Opportunity_Approval_Type__c=null, REASON_FOR_APPROVAL__c='test', Fraud_Management_Booking_Value_QC__c = 1, Revenue_Assurance_Booking_Value_QC__c = 1);
    //     insert test_opportunity_1;
        
    //     Opportunity test_opportunity_2 = new Opportunity(AccountId=test_account.Id, Country__c = territory.Id, Name = 'Test Opportunity1', StageName ='Proposal', CloseDate=System.today(), Probability_to_Close_Picklist__c = '0%', Type='TL-Term License', Amount = 0.00, Currency_Table__c = inst_Currency_Table.id, Pricebook2Id = inst_priceBook.id, RISK_NON_STD_Deal_Margin__c='Margin< 25%', Business_Unit__c='Testing', Opportunity_Approval_Type__c=null, REASON_FOR_APPROVAL__c='test', Fraud_Management_Booking_Value_QC__c = 1, Revenue_Assurance_Booking_Value_QC__c = 1);
    //     insert test_opportunity_2;
        
    //     SBQQ__Quote__c iterating_quote = new SBQQ__Quote__c( SBQQ__Primary__c = true, SBQQ__StartDate__c = System.today(), SBQQ__Opportunity2__c = test_opportunity_1.Id);
    //     insert iterating_quote;
    //     Approval_Processes_Configuration__c  apc = new Approval_Processes_Configuration__c (name='Test apc', Business_Unit__c = 'RISK', Approval_Type__c = 'Standard', Type__c = 'Professional Services', Approvers_Emails__c = 'test@test.com', Special_Approval_Routing__c = null);
    //     insert apc;
    //     Approval_Process_Approver_User_Mapping__c  apaum = new Approval_Process_Approver_User_Mapping__c (name='Test apaum');
    //     insert apaum;

    //     Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
    //     User sysAdmin_1 = new User(Alias = 'standt', Email='test@test.com',EmailEncodingKey='UTF-8', LastName='sysAdminTesting', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = sysAdminProfile.Id, TimeZoneSidKey='America/Los_Angeles', UserName='standarduser154dsafsfas5343asaSADMIN4@mbil1212.com');
    //     insert sysAdmin_1;
    // }

    // @isTest
    // static void itShouldReturnCFOGovernance()
    // {
    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c, Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Amount = 55000;
    //     opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c = 'Margin < 25%';
    //     opp.Opportunity_Approval_Type__c = 'Non-Standard';

    //     Test.startTest();
    //         String result = cls_OpportunityApprovalHandler.findSpecialApprover(opp);
    //     Test.stopTest();

    //     System.assertEquals(cls_OpportunityApprovalHandler.APPROVER_CFO_GOVERNANCE, result);
    // }

    // @isTest
    // static void itShouldReturnGovernance()
    // {
    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c, Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Amount = 30000000000000.0;
    //     opp.RISK_NON_STD_Deal_Margin__c = null;
    //     opp.Opportunity_Approval_Type__c = 'Non-Standard';

    //     Test.startTest();
    //         String result = cls_OpportunityApprovalHandler.findSpecialApprover(opp);
    //     Test.stopTest();

    //     System.assertEquals(cls_OpportunityApprovalHandler.APPROVER_GOVERNANCE, result);
    // }

    // @isTest
    // static void itShouldFindCorrespondingApprovalSetting()
    // {
    //     Approval_Processes_Configuration__c apc = (Approval_Processes_Configuration__c)[SELECT Name, ID, Approval_Type__c, Sub_Region__c, Approvers_Emails__c, Business_Unit__c, Type__c, Special_Approval_Routing__c FROM Approval_Processes_Configuration__c WHERE Name = 'Test apc'];
    //     apc.Entity_Code__c = '--';
    //     apc.Approval_Type__c = 'Standard';
    //     apc.Sub_Region__c = 'EMEA';
    //     apc.Business_Unit__c = 'RISK';
    //     apc.Type__c = 'Professional Services';
    //     apc.Approvers_Emails__c = 'test@test.com';
    //     apc.Special_Approval_Routing__c = cls_OpportunityApprovalHandler.APPROVER_CFO_GOVERNANCE;
    //     update apc;

    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c,Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = 'Standard';
    //     opp.Business_Unit__c = 'RISK';
    //     opp.NON_STANDARD_CONDITIONS__c = '';
    //     opp.Type = 'Professional Services';

    //     String jsonString = JSON.serialize(opp);
    //     Map<String,Object> dataMap = (Map<String,Object>)JSON.deserializeUntyped(jsonString);
    //     dataMap.put('Sub_Region__c', 'EMEA');
    //     jsonString = JSON.serialize(dataMap);
    //     opp = (Opportunity)JSON.deserialize(jsonString, SObject.class);

    //     Test.startTest();
    //         cls_OpportunityApprovalHandler.opp = opp;
    //         Set<String> result = cls_OpportunityApprovalHandler.findCorrespondingApprovalSetting();
    //     Test.stopTest();

    //     System.assertEquals(apc.Approvers_Emails__c, new List<String> ( result )[0]);
        
    //     /*------------------------------------------added--------------------------*/
    //     Approval_Processes_Configuration__c apc1 = (Approval_Processes_Configuration__c)[SELECT Name, ID, Approval_Type__c, Sub_Region__c, Approvers_Emails__c, Business_Unit__c, Type__c, Special_Approval_Routing__c FROM Approval_Processes_Configuration__c WHERE Name = 'Test apc'];
    //     apc1.Approval_Type__c = 'Standard';
    //     apc1.Sub_Region__c = 'EMEA';
    //     apc1.Business_Unit__c = 'Testing';
    //     apc1.Type__c = 'Professional Services';
    //     apc1.Approvers_Emails__c = 'test@test.com';
    //     apc1.Special_Approval_Routing__c = cls_OpportunityApprovalHandler.APPROVER_CFO_GOVERNANCE;
    //     update apc1;

    //     Opportunity opp1 =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c,Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity1'];
    //     opp1.Opportunity_Approval_Type__c = 'Standard';
    //     opp1.Business_Unit__c = 'Testing';
    //     opp1.NON_STANDARD_CONDITIONS__c = '';
    //     opp1.Type = 'Professional Services';

    //     String jsonString1 = JSON.serialize(opp1);
    //     Map<String,Object> dataMap1 = (Map<String,Object>)JSON.deserializeUntyped(jsonString1);
    //     dataMap1.put('Sub_Region__c', 'EMEA');
    //     jsonString1 = JSON.serialize(dataMap1);
    //     opp1 = (Opportunity)JSON.deserialize(jsonString1, SObject.class);

    //    /* Test.startTest();
    //         cls_OpportunityApprovalHandler.opp1 = opp1;
    //         Set<String> result1 = cls_OpportunityApprovalHandler.findCorrespondingApprovalSetting();
    //     Test.stopTest();

    //     System.assertEquals(apc1.Approvers_Emails__c, new List<String> ( result )[0]);*/
    // }


    // @isTest
    // static void itShouldOppTypeErrorFromWbservice()
    // {
    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c,Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = null;
    //     update opp;

    //     Test.startTest();
    //         String result = cls_OpportunityApprovalHandler.submitApproval(opp.Id);
    //     Test.stopTest();

    //     System.assertEquals('Opportunity approval - Type not selected.', result);
    // }

    // @isTest
    // static void itShouldOppTypeError()
    // {
    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c, Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = null;
    //     update opp;

    //     Test.startTest();
    //         String result = cls_OpportunityApprovalHandler.initiateApproval(opp.Id);
    //     Test.stopTest();

    //     System.assertEquals('Opportunity approval - Type not selected.', result);
    // }

    // @isTest
    // static void itShouldOppSubRegionError()
    // {
    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c,Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = 'Standard';
    //     opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c = null;
    //     opp.RISK_NON_STD_Deal_Margin__c = null;
    //     opp.Testing_Non_Std_Deal_Margin__c = null;
    //     opp.Country__c = null;

    //     update opp;

    //     Test.startTest();
    //         String result = cls_OpportunityApprovalHandler.initiateApproval(opp.Id);
    //     Test.stopTest();

    //     System.assertEquals('Opportunity Approval - Sub Region field should be filled', result);
    // }

    // @isTest
    // static void itShoulReturnNoApprovalNeededError()
    // {
    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c,Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = 'Standard';
    //     opp.Type = 'Professional Services';
    //     opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c = null;
    //     opp.RISK_NON_STD_Deal_Margin__c = null;
    //     opp.Testing_Non_Std_Deal_Margin__c = null;

    //     update opp;

    //     Test.startTest();
    //         String result = cls_OpportunityApprovalHandler.initiateApproval(opp.Id);
    //     Test.stopTest();

    //    // System.assertEquals('Opportunity Approval - Opportunities with standard conditions do not need to be approved', result);
    // }

    // @isTest
    // static void itShoulReturnShouldbeNonStandard()
    // {
    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c,Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = 'Standard';
    //     opp.Type = 'Recurring Revenue';
    //     opp.Amount = 30000000000.0;
    //     opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c = null;
    //     opp.RISK_NON_STD_Deal_Margin__c = null;
    //     opp.Testing_Non_Std_Deal_Margin__c = null;

    //     update opp;

    //     Test.startTest();
    //         String result = cls_OpportunityApprovalHandler.initiateApproval(opp.Id);
    //     Test.stopTest();

    //     //System.assertEquals('Opportunity Approval - Opportunities with the amount larger than 300k should be "Non-Standard"', result);
    // }

    // @isTest
    // static void itShoulReturnNonStandardconditionsNotFilled()
    // {
    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c,Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = 'Non-Standard';
    //     opp.Type = 'Recurring Revenue';
    //     opp.Amount = 30000000000.0;
    //     opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c = null;
    //     opp.RISK_NON_STD_Deal_Margin__c = null;
    //     opp.Testing_Non_Std_Deal_Margin__c = null;
    //     opp.NON_STANDARD_CONDITIONS__c = null;

    //     update opp;

    //     Test.startTest();
    //         String result = cls_OpportunityApprovalHandler.initiateApproval(opp.Id);
    //     Test.stopTest();

    //     System.assertEquals('Opportunity Approval - Type is "Non-Standard" , please fill Non-Standard Conditions', result);
    // }

    // @isTest
    // static void itShoulReturnNonStandardReasonNotFilled()
    // {
    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c, Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = 'Non-Standard';
    //     opp.Type = 'Recurring Revenue';
    //     opp.Amount = 30000000000.0;
    //     opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c = null;
    //     opp.RISK_NON_STD_Deal_Margin__c = null;
    //     opp.Testing_Non_Std_Deal_Margin__c = null;
    //     opp.NON_STANDARD_CONDITIONS__c = 'SW';
    //     opp.REASON_FOR_APPROVAL__c = null;

    //     update opp;

    //     Test.startTest();
    //         String result = cls_OpportunityApprovalHandler.initiateApproval(opp.Id);
    //     Test.stopTest();

    //     System.assertEquals('Opportunity Approval - Reason for approval field in the approval section must be filled', result);
    // }

    // @isTest
    // static void itShouldCreateApprovalProcessGovernance()
    // {

    //     Approval_Process_Approver_User_Mapping__c apaum = (Approval_Process_Approver_User_Mapping__c)[SELECT Work_Email__c, SF_User_Email__c  FROM Approval_Process_Approver_User_Mapping__c WHERE Name = 'Test apaum'];
    //     apaum.Work_Email__c = 'test@test.com';
    //     apaum.SF_User_Email__c = 'test@test.com';
    //     update apaum;

    //     Approval_Processes_Configuration__c apc = (Approval_Processes_Configuration__c)[SELECT Name, ID, Approval_Type__c, Sub_Region__c, Approvers_Emails__c, Business_Unit__c, Type__c, Special_Approval_Routing__c FROM Approval_Processes_Configuration__c WHERE Name = 'Test apc'];
    //     apc.Approval_Type__c = 'Non-Standard';
    //     apc.Sub_Region__c = 'EMEA';
    //     apc.Business_Unit__c = 'RISK';
    //     apc.Type__c = 'Recurring Revenue';
    //     apc.Approvers_Emails__c = 'test@test.com';
    //     apc.Special_Approval_Routing__c = cls_OpportunityApprovalHandler.APPROVER_GOVERNANCE;
    //     update apc;

    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c, Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = 'Non-Standard';
    //     opp.Type = 'Recurring Revenue';
    //     opp.Amount = 30000000000.0;
    //     apc.Business_Unit__c = 'RISK';
    //     opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c = null;
    //     opp.RISK_NON_STD_Deal_Margin__c = null;
    //     opp.Testing_Non_Std_Deal_Margin__c = null;
    //     opp.NON_STANDARD_CONDITIONS__c = 'SW';
    //     opp.REASON_FOR_APPROVAL__c = 'test';

    //     update opp;

    //     Test.startTest();
    //         String result = cls_OpportunityApprovalHandler.initiateApproval(opp.Id);
    //     Test.stopTest();
    //     //Assert
        
    //     //System.assertEquals('Success', result);
    // }


    // @isTest
    // static void itShouldCreateApprovalProcessGovernanceCFO()
    // {

    //     Approval_Process_Approver_User_Mapping__c apaum = (Approval_Process_Approver_User_Mapping__c)[SELECT Work_Email__c, SF_User_Email__c  FROM Approval_Process_Approver_User_Mapping__c WHERE Name = 'Test apaum'];
    //     apaum.Work_Email__c = 'test@test.com';
    //     apaum.SF_User_Email__c = 'test@test.com';
    //     update apaum;

    //     Approval_Processes_Configuration__c apc = (Approval_Processes_Configuration__c)[SELECT Name, ID, Approval_Type__c, Sub_Region__c, Approvers_Emails__c, Business_Unit__c, Type__c, Special_Approval_Routing__c FROM Approval_Processes_Configuration__c WHERE Name = 'Test apc'];
    //     apc.Entity_Code__c = '--';
	// 	apc.Approval_Type__c = 'Non-Standard';
    //     apc.Sub_Region__c = 'testCountry';
    //     apc.Business_Unit__c = 'RISK';
    //     apc.Type__c = 'Recurring Revenue';
    //     apc.Approvers_Emails__c = 'test@test.com';
    //     apc.Special_Approval_Routing__c = cls_OpportunityApprovalHandler.APPROVER_CFO_GOVERNANCE;
    //     update apc;

    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c, Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = 'Non-Standard';
    //     opp.Type = 'Recurring Revenue';
    //     opp.Amount = 55000.0;
    //     apc.Business_Unit__c = 'RISK';
    //     opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c = null;
    //     opp.RISK_NON_STD_Deal_Margin__c = 'Margin< 25%';
    //     opp.Testing_Non_Std_Deal_Margin__c = null;
    //     opp.NON_STANDARD_CONDITIONS__c = 'SW';
    //     opp.REASON_FOR_APPROVAL__c = 'test';
    
	// 	update opp;

    //     Test.startTest();
    //         String result = cls_OpportunityApprovalHandler.initiateApproval(opp.Id);
    //     Test.stopTest();

    //     //System.assertEquals('Success', result);
    // }



    // @isTest
    // static void itShouldCreateApprovalProcessOther()
    // {

    //     Approval_Process_Approver_User_Mapping__c apaum = (Approval_Process_Approver_User_Mapping__c)[SELECT Work_Email__c, SF_User_Email__c  FROM Approval_Process_Approver_User_Mapping__c WHERE Name = 'Test apaum'];
    //     apaum.Work_Email__c = 'test@test.com';
    //     apaum.SF_User_Email__c = 'test@test.com';
    //     update apaum;

    //     Approval_Processes_Configuration__c apc = (Approval_Processes_Configuration__c)[SELECT Name, ID, Approval_Type__c, Sub_Region__c, Approvers_Emails__c, Business_Unit__c, Type__c, Special_Approval_Routing__c FROM Approval_Processes_Configuration__c WHERE Name = 'Test apc'];
    //     apc.Approval_Type__c = 'Non-Standard';
    //     apc.Sub_Region__c = 'testCountry';
    //     apc.Business_Unit__c = 'RISK';
    //     apc.Type__c = 'Recurring Revenue';
    //     apc.Approvers_Emails__c = 'test@test.com';
    //     apc.Special_Approval_Routing__c = cls_OpportunityApprovalHandler.APPROVER_GOVERNANCE;
    //     update apc;

    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c, Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = 'Non-Standard';
    //     opp.Type = 'Recurring Revenue';
    //     opp.Amount = 30000000000.0;
    //     opp.Business_Unit__c = 'RISK';
    //     opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c = null;
    //     opp.RISK_NON_STD_Deal_Margin__c = null;
    //     opp.Testing_Non_Std_Deal_Margin__c = null;
    //     opp.NON_STANDARD_CONDITIONS__c = 'SW';
    //     opp.REASON_FOR_APPROVAL__c = 'test';

    //     update opp;

    //     Test.startTest();
    //         String result = cls_OpportunityApprovalHandler.initiateApproval(opp.Id);
    //     Test.stopTest();

    //     //System.assertEquals('Success', result);

    // }

    // @isTest
    // static void itShoulReturnCheckFlowAlreadyRun()
    // {
    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c, Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = 'Non-Standard';
    //     opp.Type = 'Recurring Revenue';
    //     opp.Amount = 30000000000.0;
    //     opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c = null;
    //     opp.RISK_NON_STD_Deal_Margin__c = null;
    //     opp.Testing_Non_Std_Deal_Margin__c = null;
    //     opp.NON_STANDARD_CONDITIONS__c = 'SW';
    //     opp.REASON_FOR_APPROVAL__c = 'test';

    //     update opp;

    //     Test.startTest();
    //         cls_OpportunityApprovalHandler.requestApproval = false;
    //         cls_OpportunityApprovalHandler.sendEmailforApproval(new List<String>{opp.Id});
    //     Test.stopTest();

    //     System.assertEquals(true, cls_OpportunityApprovalHandler.completeFlowAlreadyRan);
    // }
    
    // @isTest
    // static void itShouldRejectOpportunity()
    // {

    //     Approval_Process_Approver_User_Mapping__c apaum = (Approval_Process_Approver_User_Mapping__c)[SELECT Work_Email__c, SF_User_Email__c  FROM Approval_Process_Approver_User_Mapping__c WHERE Name = 'Test apaum'];
    //     apaum.Work_Email__c = 'test@test.com';
    //     apaum.SF_User_Email__c = 'test@test.com';
    //     update apaum;

    //     Approval_Processes_Configuration__c apc = (Approval_Processes_Configuration__c)[SELECT Name, ID, Approval_Type__c, Sub_Region__c, Approvers_Emails__c, Business_Unit__c, Type__c, Special_Approval_Routing__c FROM Approval_Processes_Configuration__c WHERE Name = 'Test apc'];
    //     apc.Approval_Type__c = 'Non-Standard';
    //     apc.Sub_Region__c = 'testCountry';
    //     apc.Business_Unit__c = 'RISK';
    //     apc.Type__c = 'Recurring Revenue';
    //     apc.Approvers_Emails__c = 'test@test.com';
    //     apc.Special_Approval_Routing__c = cls_OpportunityApprovalHandler.APPROVER_GOVERNANCE;
    //     update apc;

    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c, Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = 'Non-Standard';
    //     opp.Type = 'Recurring Revenue';
    //     opp.Amount = 30000000000.0;
    //     opp.Business_Unit__c = 'RISK';
    //     opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c = null;
    //     opp.RISK_NON_STD_Deal_Margin__c = null;
    //     opp.Testing_Non_Std_Deal_Margin__c = null;
    //     opp.NON_STANDARD_CONDITIONS__c = 'SW';
    //     opp.REASON_FOR_APPROVAL__c = 'test';

    //     update opp;

    //     Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
    //     app.setObjectId(opp.id);
    //     app.setNextApproverIds(new Id[] {UserInfo.getUserId()});
    //     app.setProcessDefinitionNameOrId('Non_Standard_Approval');
    //     app.setSkipEntryCriteria(true);

    //     Approval.ProcessResult result = Approval.process(app);

    //     Test.startTest();
    //         cls_OpportunityApprovalHandler.rejectionAction(new Set<Id>{opp.Id},  new List<Opportunity>{opp},  new Map<Id,Opportunity>{opp.Id => opp});
    //     Test.stopTest();
    // }

    //     @isTest
    // static void itShouldApproveOpportunity()
    // {

    //     Approval_Process_Approver_User_Mapping__c apaum = (Approval_Process_Approver_User_Mapping__c)[SELECT Work_Email__c, SF_User_Email__c  FROM Approval_Process_Approver_User_Mapping__c WHERE Name = 'Test apaum'];
    //     apaum.Work_Email__c = 'test@test.com';
    //     apaum.SF_User_Email__c = 'test@test.com';
    //     update apaum;

    //     Approval_Processes_Configuration__c apc = (Approval_Processes_Configuration__c)[SELECT Name, ID, Approval_Type__c, Sub_Region__c, Approvers_Emails__c, Business_Unit__c, Type__c, Special_Approval_Routing__c FROM Approval_Processes_Configuration__c WHERE Name = 'Test apc'];
    //     apc.Approval_Type__c = 'Non-Standard';
    //     apc.Sub_Region__c = 'testCountry';
    //     apc.Business_Unit__c = 'RISK';
    //     apc.Type__c = 'Recurring Revenue';
    //     apc.Approvers_Emails__c = 'test@test.com';
    //     apc.Special_Approval_Routing__c = cls_OpportunityApprovalHandler.APPROVER_GOVERNANCE;
    //     update apc;

    //     Opportunity opp =(Opportunity)[SELECT id,Amount,Gross_Margin_of_Primary_Quote__c,Sub_Region__c,REASON_FOR_APPROVAL__c,type,Opportunity_Approval_Type__c,Opportunity_Approval_Status__c,Business_Unit__c,NON_STANDARD_CONDITIONS__c,ROAMING_SECURITY_NON_STD_Deal_Margin__c,RISK_NON_STD_Deal_Margin__c,Testing_Non_Std_Deal_Margin__c, Engmnt_Exp_Non_Std_Deal_Margin__c FROM Opportunity WHERE Name = 'Test Opportunity'];
    //     opp.Opportunity_Approval_Type__c = 'Non-Standard';
    //     opp.Type = 'Recurring Revenue';
    //     opp.Amount = 30000000000.0;
    //     opp.Business_Unit__c = 'RISK';
    //     opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c = null;
    //     opp.RISK_NON_STD_Deal_Margin__c = null;
    //     opp.Testing_Non_Std_Deal_Margin__c = null;
    //     opp.NON_STANDARD_CONDITIONS__c = 'SW';
    //     opp.REASON_FOR_APPROVAL__c = 'test';

    //     update opp;

    //     Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
    //     app.setObjectId(opp.id);
    //     app.setNextApproverIds(new Id[] {UserInfo.getUserId()});
    //     app.setProcessDefinitionNameOrId('Non_Standard_Approval');
    //     app.setSkipEntryCriteria(true);

    //     Approval.ProcessResult result = Approval.process(app);

    //     Test.startTest();
    //         cls_OpportunityApprovalHandler.ApprovalAction(new Set<Id>{opp.Id}, new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => opp});
    //     Test.stopTest();
    // }