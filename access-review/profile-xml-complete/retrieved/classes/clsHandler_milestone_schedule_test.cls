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
Name                    clsHandler_milestone_schedule_test
Developed By            West Monroe Partners
Purpose                 Test class
For APEX?               clsHandler_milestone_schedule
Created date            1/23/2017
*************************************************************************************/
@isTest
private class clsHandler_milestone_schedule_test {
    /*************************************************************************************
    Method Name             testSetup_clsHandler
    Test Purpose            Setup method to create the following:
                            * Account
                            * Opportunity
                            * Milestone
    *************************************************************************************/
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
        

        System.runAs(sysAdmin_1){
            //Giving the finance user permission set to edit information
            PermissionSet permissonSetToEditDeleteOpp = [SELECT ID From PermissionSet WHERE Name = 'Modify_All_Opportunities_Quotes' LIMIT 1];
            insert new PermissionSetAssignment(AssigneeId = financeUser_1.id, PermissionSetId = permissonSetToEditDeleteOpp.Id );

            //creating the price book
            Pricebook2 inst_priceBook = new Pricebook2(Name = 'Test Class pricebook', Description = 'Test Class pricebook', IsActive = true );
            insert inst_priceBook;
            //creating the product
            Product2 inst_product = new Product2(Name = 'Testing Product', Family = 'Software License');
            insert inst_product;
            //creating the price book entry
            list<PricebookEntry> list_Pricebook = new list<PricebookEntry>();
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

        //Creating account
        Account test_account = new Account();
        /*** Running the next piece of code with the
             running user as - salesUser_1
         ***/
        System.runAs(salesUser_1){
            test_account.Name = 'Test Account';
            insert test_account;
        }
            //Creating the account team
            list<AccountTeamMember> list_accountTeamMembers = new list<AccountTeamMember>();
            AccountTeamMember inst_accountTeamMember = new AccountTeamMember(   AccountAccessLevel = 'Edit',
                                                                                AccountId = test_account.id,
                                                                                CaseAccessLevel = 'Edit',
                                                                                ContactAccessLevel='Edit',
                                                                                OpportunityAccessLevel='Edit',
                                                                                TeamMemberRole='Owner',
                                                                                UserId = UserInfo.getUserId()
                                                                            );

            list_accountTeamMembers.add(inst_accountTeamMember);
            inst_accountTeamMember = new AccountTeamMember(   AccountAccessLevel = 'Edit',
                                                                                AccountId = test_account.id,
                                                                                CaseAccessLevel = 'Edit',
                                                                                ContactAccessLevel='Edit',
                                                                                OpportunityAccessLevel='Edit',
                                                                                TeamMemberRole='Project Manager',
                                                                                UserId = salesUser_2.Id
                                                                            );
            list_accountTeamMembers.add(inst_accountTeamMember);

            insert list_accountTeamMembers;
        System.runAs(salesUser_1){
            Opportunity test_opportunity = new Opportunity(AccountId=test_account.Id,
                                                               Name = 'Test Opportunity',
                                                               StageName    ='Proposal',
                                                               CloseDate=System.today(),
                                                               //CurrencyIsoCode = 'USD',
                                                               Probability_to_Close_Picklist__c = '0%',
                                                               Type='TL-Term License',
                                                               Currency_Table__c = inst_Currency_Table.id,
                                                               Amount = 0.00,
                                                               Business_Unit__c = 'Roaming'
                                                               );
            insert test_opportunity;
        }
    }
    /*************************************************************************************
    Method Name             testHandler_checkForMilestoneAndProject
    Test Purpose            Single entry - positive case
    End result              7 milestone records to be created
                            1 project record to be created
    *************************************************************************************/
    @isTest
    static void testHandler_checkForMilestoneAndProject(){
        //Opportunity is already inserted.
        //Querying the opportunity
        Opportunity test_opp = [SELECT ID from Opportunity LIMIT 1];

        //Querying the milestones related to the opportunity
        list<Milestone__c> testList_Milestone = [SELECT ID,ProductCategory__c  from Milestone__c ];
        //Asserting if there are 7 milestones created
        System.assertEquals(7, testList_Milestone.size());
        for(Milestone__c iterating_milestone : testList_Milestone){
            System.debug('Milestone info >> ' + iterating_milestone);
        }

        //Querying the projects related to the opportunity
        list<Project__c> testList_Project = [SELECT ID,Name  from Project__c ];
        //Asserting if there is 1 project created
        System.assertEquals(1, testList_Project.size());
    }

    /*************************************************************************************
    Method Name             testhandler_quoteSharing
    Test Purpose            Single entry - positive case
    End result              APEX sharing as per opporutnity team
    *************************************************************************************/
    @isTest
    static void testhandler_quoteSharing(){

        //Now inserting the quote as the sales user
        User salesUser = [SELECT ID,Name from User WHERE Lastname='SalesUserTesting1' LIMIT 1];


        //creating the product and price book for the quote line item to be created
        System.runAs(salesUser){
            //Opportunity is already inserted.
            //Querying the opportunity
            Opportunity test_opp = [SELECT ID from Opportunity LIMIT 1];
            //inserting quote
            SBQQ__Quote__c iterating_quote = new SBQQ__Quote__c(
                                                                    SBQQ__Primary__c = true,
                                                                    SBQQ__StartDate__c = System.today(),
                                                                    SBQQ__Opportunity2__c = test_opp.Id
                                                                );
            insert iterating_quote;

        }
        System.debug('All APEX sharing >> ' + [SELECT Id,UserorGroupId,RowCause from SBQQ__Quote__Share]);
        //System.assertEquals(1,[SELECT Id FROM SBQQ__Quote__Share WHERE RowCause='Opp_Team__c' AND UserOrGroupId=:salesUser.Id].size());
    }

    /*************************************************************************************
    Method Name             testhandler_creatingSecondProject
    Test Purpose            Single entry - positive case
    End result              creation of 7 additional milestones
    *************************************************************************************/
    @isTest
    static void testhandler_creatingSecondProject(){

        //Now inserting the quote as the sales user
        User financeUser = [SELECT ID,Name from User WHERE Lastname='FinanceUserTesting' LIMIT 1];

        //System.runAs(financeUser){
            //Opportunity is already inserted.
            //Querying the opportunity
            Opportunity test_opp = [SELECT ID from Opportunity LIMIT 1];
            System.debug('Queried Opportuinty as Finance >>>> ' + test_opp);
            Project__c inst_newProject = new Project__c(
                                                            Name='secondProjectForOpportunity',
                                                            Opportunity__c = test_opp.Id
                                                        );
            System.debug('Before insert project  >>>> ' + inst_newProject);
            insert inst_newProject;
            System.debug('Before insert project  >>>> ' + inst_newProject);
            //Querying the milestones related to the opportunity
            list<Milestone__c> testList_Milestone = [SELECT ID,ProductCategory__c  from Milestone__c WHERE Project__c =:inst_newProject.id];
            //Asserting if there are 7 milestones created
            System.assertEquals(7, testList_Milestone.size());

        //}
    }
    /*************************************************************************************
    Method Name             testhandler_auraHandlerMethods
    Test Purpose            Single entry - positive case
    End result              all methods from the lightning components
    *************************************************************************************/
    @isTest
    static void testhandler_auraHandlerMethods(){
        //
        //Now inserting the quote as the sales user
        User salesUser = [SELECT ID,Name from User WHERE Lastname='SalesUserTesting1' LIMIT 1];
        System.runAs(salesUser){
            //Opportunity is already inserted.
            //Querying the opportunity
            Opportunity test_opp = [SELECT ID from Opportunity LIMIT 1];
            //Querying the pricebook
            PricebookEntry inst_priceBookEntry = [SELECT Id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Product2.name ='Testing Product' AND Pricebook2.name='Test Class pricebook' LIMIT 1];
            test_opp.Pricebook2Id = inst_priceBookEntry.Pricebook2Id;
            update test_opp;
            //getting the project Id
            clshandler_milestone_schedule.fetchProjectForOpportunityId((string)test_opp.Id);
            //Getting milestone headers
            clshandler_milestone_schedule.fetchMilestoneHeaders();
            //Getting the project and related milestones
            Project__c relatedProject = [SELECT Id FROM Project__c WHERE Opportunity__c=:test_opp.id LIMIT 1];
            //inserting quote line items
            OpportunityLineItem iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = inst_priceBookEntry.Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 7500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Milestone',
                                                                            Project__c =relatedProject.Id
                                                                        );
            insert iterating_lineItem;
            //Using Aura handler to get the project details
            Project__c completeProjectWithDetails = clshandler_milestone_schedule.fetchProjectDetails(relatedProject.id);
            //Getting the milestones
            list<Milestone__c> list_relatedMilestones = new list<Milestone__c>();
            list_relatedMilestones = clshandler_milestone_schedule.fetchMilestoneRows(relatedProject.Id);
            //Save method
            clshandler_milestone_schedule.saveMethod(completeProjectWithDetails, list_relatedMilestones);
        }
    }
}