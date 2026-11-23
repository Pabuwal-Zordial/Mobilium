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
Name                    test_clsPRTemplates
Developed By            West Monroe Partners
Purpose                 Test class
Created date            05/10/2017
*************************************************************************************/
@isTest
public with sharing class test_clsPRTemplates {
    @testSetup
    static void testSetup_clsHandler() {

        //querying for the sales user profile
        Profile salesUserProfile = [SELECT Id FROM Profile WHERE Name='Mobileum - Sales User'];
        Profile financeUserProfile = [SELECT Id FROM Profile WHERE Name='Mobileum - Finance User Limited'];
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        list<User> list_user = new list<user>();
        Currency_Table__c inst_Currency_Table;
        User salesUser_1 = new User(Alias = 'standt', Email='standarduser@mbil1212.com',
           EmailEncodingKey='UTF-8', LastName='SalesUserTesting1', LanguageLocaleKey='en_US',
           LocaleSidKey='en_US', ProfileId = salesUserProfile.Id,
           TimeZoneSidKey='America/Los_Angeles', UserName='standarduser12234@mbil1212.com');

        list_user.add(salesUser_1);

        User salesUser_2 = new User(Alias = 'standt', Email='standarduser@mbil1212.com',
           EmailEncodingKey='UTF-8', LastName='SalesUserTesting2', LanguageLocaleKey='en_US',
           LocaleSidKey='en_US', ProfileId = salesUserProfile.Id,
           TimeZoneSidKey='America/Los_Angeles', UserName='standarduser15453434@mbil1212.com');

        list_user.add(salesUser_2);

        User financeUser_1 = new User(Alias = 'standt', Email='standarduser@mbil1212.com',
           EmailEncodingKey='UTF-8', LastName='FinanceUserTesting', LanguageLocaleKey='en_US',
           LocaleSidKey='en_US', ProfileId = financeUserProfile.Id,
           TimeZoneSidKey='America/Los_Angeles', UserName='standarduser154dsafsfas53434@mbil1212.com');

        list_user.add(financeUser_1);

        User sysAdmin_1 = new User(Alias = 'standt', Email='standarduser@mbil1212.com',
           EmailEncodingKey='UTF-8', LastName='sysAdminTesting', LanguageLocaleKey='en_US',
           LocaleSidKey='en_US', ProfileId = sysAdminProfile.Id,
           TimeZoneSidKey='America/Los_Angeles', UserName='standarduser154dsafsfas5343asaSADMIN4@mbil1212.com');

        list_user.add(sysAdmin_1);

        insert list_user;

        Product2 inst_product1 = new Product2();
        Pricebook2 inst_priceBook = new Pricebook2();
        System.runAs(sysAdmin_1){
            //Giving the finance user permission set to edit information
            PermissionSet permissonSetToEditDeleteOpp = [SELECT ID From PermissionSet WHERE Name = 'Modify_All_Opportunities_Quotes' LIMIT 1];
            insert new PermissionSetAssignment(AssigneeId = financeUser_1.id, PermissionSetId = permissonSetToEditDeleteOpp.Id );

            //creating the price book
            inst_priceBook = new Pricebook2(Name = 'Test Class pricebook', Description = 'Test Class pricebook', IsActive = true );
            insert inst_priceBook;
            //creating the product
            list<Product2> list_product = new list<Product2>();
            inst_product1 = new Product2(Name = 'Testing Product 1', Family = 'Annual Maintenance (AMC)');
            list_product.add(inst_product1);
            Product2 inst_product2 = new Product2(Name = 'Testing Product 2', Family = 'Implementation Services');
            list_product.add(inst_product2);
            insert list_product;
            //creating the price book entry
            list<PricebookEntry> list_Pricebook = new list<PricebookEntry>();
            PricebookEntry standard_priceBookEntry = new PricebookEntry(
                                                                        Pricebook2Id =Test.getStandardPricebookId(),
                                                                        Product2Id = inst_product1.Id,
                                                                        UnitPrice = 10000,
                                                                        isActive = false
                                                                       );
            list_Pricebook.add(standard_priceBookEntry);
             PricebookEntry custom_priceBookEntry = new PricebookEntry(
                                                                        Pricebook2Id = inst_priceBook.id,
                                                                        Product2Id = inst_product1.Id,
                                                                        UnitPrice = 10000,
                                                                        isActive = true
                                                                       );
            list_Pricebook.add(custom_priceBookEntry);
             standard_priceBookEntry = new PricebookEntry(
                                                                        Pricebook2Id =Test.getStandardPricebookId(),
                                                                        Product2Id = inst_product2.Id,
                                                                        UnitPrice = 10000,
                                                                        isActive = false
                                                                       );
            list_Pricebook.add(standard_priceBookEntry);
              custom_priceBookEntry = new PricebookEntry(
                                                                        Pricebook2Id = inst_priceBook.id,
                                                                        Product2Id = inst_product2.Id,
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

        //Creating account
        Account test_account = new Account();
        /*** Running the next piece of code with the
             running user as - salesUser_1
         ***/
        System.runAs(salesUser_1){
            test_account.Name = 'Test Account';
            insert test_account;

            Opportunity test_opportunity = new Opportunity(AccountId=test_account.Id,
                                                               Name = 'Test Opportunity',
                                                               StageName    ='Proposal',
                                                               CloseDate=System.today(),
                                                               //CurrencyIsoCode = 'USD',
                                                               Probability_to_Close_Picklist__c = '0%',
                                                               Type='TL-Term License',
                                                               Amount = 0.00,
                                                               Pricebook2Id = inst_priceBook.id,
                                                               Currency_Table__c = inst_Currency_Table.id,
                                                               Business_Unit__c = 'Roaming'
                                                               );
            insert test_opportunity;


            SBQQ__Quote__c test_quote = new SBQQ__Quote__c(
                                                            SBQQ__Opportunity2__c =test_opportunity.Id,
                                                            SBQQ__StartDate__c = System.today(),
                                                            SBQQ__Primary__c = true 
            );

            insert test_quote;
            SBQQ__QuoteLineGroup__c test_quoteGroup = new SBQQ__QuoteLineGroup__c(
                                                            SBQQ__Quote__c=test_Quote.id,
                                                            Name = 'Test Group'
            );
            insert test_quoteGroup;
            SBQQ__QuoteLine__c test_quoteLine = new SBQQ__QuoteLine__c(
                                                            SBQQ__Quote__c = test_quote.id,
                                                            SBQQ__Product__c = inst_product1.id,
                                                            SBQQ__Group__c =test_quoteGroup.id,
                                                SBQQ__Quantity__c = 1,
                                                SBQQ__ListPrice__c = 10000,
                                                SBQQ__RegularPrice__c = 10000
            );
            insert test_quoteLine;

          test_quote.SBQQ__Primary__c = true;
          update test_quote;
        }
    }

     /*************************************************************************************
    Method Name             testhandler_PRtemplate
    *************************************************************************************/
    @isTest
    static void testhandler_PRtemplate(){
        Project__c test_PR = [SELECT ID FROM Project__c];
        Opportunity test_opp = [SELECT Id,Pricebook2Id from Opportunity];
        Product2 test_prod =[SELECT ID from Product2 Where Name='Testing Product 1'];
        list<PricebookEntry> test_entry = [SELECT Id FROM PricebookEntry];
       /*
       System.debug('Quote id is >> ' + test_PR);
       OpportunityLineItem inst_OLI = new OpportunityLineItem();
       inst_OLI.OpportunityId = test_opp.Id;
       inst_OLI.Project__c = test_PR.Id;
       inst_OLI.Quantity = 1;
       inst_OLI.TotalPrice = 100;
       inst_OLI.PriceBookEntryId = test_entry[0].Id;
       insert inst_OLI;
        */
        //Standard controller code
        ApexPages.StandardController sc = new ApexPages.StandardController(test_PR);
        ctrlExt_purchaseReq_template inst_ctrlExt_PRTemplate = new ctrlExt_purchaseReq_template(sc);

        PageReference pageRef = Page.vf_nonStd_purchaseRequest;
        pageRef.getParameters().put('id', String.valueOf(test_PR.Id));
        Test.setCurrentPage(pageRef);

        
    }


}