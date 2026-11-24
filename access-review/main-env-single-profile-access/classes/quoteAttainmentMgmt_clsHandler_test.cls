/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
 /*************************************************************************************
Name                    quoteAttainmentMgmt_clsHandler_test
Developed By            West Monroe Partners
Purpose                 Test class
Created date            07/07/2017
*************************************************************************************/
@isTest
private class quoteAttainmentMgmt_clsHandler_test 
{
    @testSetup
    static void testSetup_clsHandler() 
    {
       //querying for the sales user profile
        Profile salesUserProfile = [SELECT Id FROM Profile WHERE Name='Mobileum - Sales User'];
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        Currency_Table__c inst_Currency_Table;
        list<PricebookEntry> list_Pricebook = new list<PricebookEntry>();
        User sysAdmin_1 = new User(Alias = 'standt', Email='standarduser@mbil1212.com',
                                   EmailEncodingKey='UTF-8', LastName='sysAdminTesting', LanguageLocaleKey='en_US',
                                   LocaleSidKey='en_US', ProfileId = sysAdminProfile.Id,
                                   TimeZoneSidKey='America/Los_Angeles', UserName='standarduser154dsafsfas5343asaSADMIN4@mbil1212.com');
        insert sysAdmin_1;

        User sysAdmin_2 = new User(Alias = 'st21andt', Email='standardus2131er@mbil1212.com',
                                   EmailEncodingKey='UTF-8', LastName='sysAdminTesting2', LanguageLocaleKey='en_US',
                                   LocaleSidKey='en_US', ProfileId = sysAdminProfile.Id,
                                   TimeZoneSidKey='America/Los_Angeles', UserName='standarduser213154dsafsfas5343asaSADMIN4@mbil1212.com');
        insert sysAdmin_2;

        User salesUser_1 = new User(Alias = 'standt', Email='standarduser@mbil1212.com',
                                       EmailEncodingKey='UTF-8', LastName='SalesUserTesting1', LanguageLocaleKey='en_US',
                                       LocaleSidKey='en_US', ProfileId = salesUserProfile.Id,
                                       TimeZoneSidKey='America/Los_Angeles', UserName='standarduser12234@mbil1212.com',
                                       SGM__c = sysAdmin_1.id, ManagerId = sysAdmin_1.id, CRO__c = sysAdmin_1.id);

        insert salesUser_1;
        System.runAs(sysAdmin_1)
        {
            //creating the products
            list<Product2> list_product = new list<Product2>();
            Product2 inst_product = new Product2(Name = 'Testing Product',
                                         Family = 'Annual Maintenance (AMC)',
                                         Business_Line__c = 'Roaming');
            insert inst_product;

            //creating the price book entry
             //creating the price book
            Pricebook2 inst_priceBook = new Pricebook2(Name = 'Test Class pricebook', Description = 'Test Class pricebook', IsActive = true );
            insert inst_priceBook;

            //creating the price book entry
            PricebookEntry standard_priceBookEntry = new PricebookEntry(
                                                                        Pricebook2Id =Test.getStandardPricebookId(),
                                                                        Product2Id = inst_product.Id,
                                                                        UnitPrice = 10000,
                                                                        isActive = false
                                                                       );
            list_Pricebook.add(standard_priceBookEntry);
             PricebookEntry custom_priceBookEntry = new PricebookEntry(
                                                                        Pricebook2Id = inst_priceBook.id,
                                                                        Product2Id = inst_product.Id,
                                                                        UnitPrice = 10000,
                                                                        isActive = true
                                                                       );
            list_Pricebook.add(custom_priceBookEntry);

            insert list_Pricebook;

            //creating the currency records
            inst_Currency_Table = new Currency_Table__c(
                                                            Name = 'INR',
                                                            Conversion_Rate__c = 0.15
                                                            );
              
            //DML - currency
            insert inst_Currency_Table;
        }

        //Logging in as salesuser
        //Creating account
        Account test_account = new Account();
        /*** Running the next piece of code with the
             running user as - salesUser_1
         ***/
        System.runAs(salesUser_1)
        {
            test_account.Name = 'Test Account';
            insert test_account;

            Opportunity test_opportunity = new Opportunity(AccountId=test_account.Id,
                                                           Name = 'Test Opportunity',
                                                           StageName    ='White Space',
                                                           CloseDate = System.today(),
                                                           //CurrencyIsoCode = 'USD',
                                                           Probability_to_Close_Picklist__c = '0%',
                                                           Type='TL-Term License',
                                                           Amount = 0.00,
                                                           Currency_Table__c = inst_Currency_Table.id,
                                                           Pricebook2Id = Test.getStandardPricebookId(),
                                                           Business_Unit__c = 'Roaming'
                                                           );
            insert test_opportunity;

            //Querying the pricebook
            PricebookEntry inst_priceBookEntry = [SELECT Id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Product2.name ='Testing Product' AND Pricebook2.name='Test Class pricebook' LIMIT 1];
            test_opportunity.Pricebook2Id = inst_priceBookEntry.Pricebook2Id;
            update test_opportunity;

            Project__c relatedProject = [SELECT Id FROM Project__c WHERE Opportunity__c=:test_opportunity.id LIMIT 1];

            //inserting quote line items
            list<OpportunityLineItem> list_OpportunityLineItem = new list<OpportunityLineItem>();
            OpportunityLineItem iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opportunity.Id,
                                                                            pricebookentryId = inst_priceBookEntry.Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 7500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Milestone',
                                                                            Project__c =relatedProject.Id,
                                                                            Business_Line__c = 'Roaming');
            insert iterating_lineItem; 
        }
    }
    /*************************************************************************************
    Method Name             testhandler_mtd1
    *************************************************************************************/
    @isTest
    static void testhandler_mtd1()
    {
        //Now inserting the quote as the sales user
        User sysAdmin = [SELECT ID,Name from User WHERE Lastname='sysAdminTesting' LIMIT 1];
        User sysAdmin2 = [SELECT ID,Name from User WHERE Lastname='sysAdminTesting2' LIMIT 1];
        User salesUser = [SELECT ID,Name,CRO__c from User WHERE Lastname='SalesUserTesting1' LIMIT 1];
        System.runAs(sysAdmin)
        {
            //creating the quota for the sales users
            Quota__c iterating_quota = new Quota__c(    Business_Line__c = 'Roaming',
                                                        Is_BU_head__c = false,
                                                        Period_Date__c = System.today(),
                                                        Quota_Owner__c = salesuser.id,
                                                        Target_in_USD__c = 10000
                                                    );
            insert iterating_quota;

            //changing user manager
            salesUser.CRO__c = sysAdmin2.id;
            update salesUser;

        }
        System.runAs(salesUser)
        {
            Opportunity test_opp = [SELECT ID,StageName from Opportunity LIMIT 1 FOR UPDATE];
            test_opp.StageName = 'Opportunity';
            update test_opp;
            /*OpportunityLineItem test_oppLine = [SELECT ID, UnitPrice from OpportunityLineItem LIMIT 1];
            test_oppLine.UnitPrice = 8000;
            update test_oppLine;*/
        }
    }
}