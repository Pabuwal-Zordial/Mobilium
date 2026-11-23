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
Name                    clsHandler_billingSchedule_project_test
Developed By            West Monroe Partners
Purpose                 Test class
For APEX?               clsHandler_billingSchedule_project
Created date            2/28/2017
*************************************************************************************/
@isTest
private class clsHandler_billingSchedule_project_test {

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
            Product2 inst_product1 = new Product2(Name = 'Testing Product 1', Family = 'Annual Maintenance (AMC)');
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
                                                               Currency_Table__c = inst_Currency_Table.id,
                                                               Pricebook2Id = inst_priceBook.id,
                                                               Company_Code__c = 'Mobileum Inc.',
                                                               Business_Unit__c = 'Roaming'
                                                               );
            insert test_opportunity;
        }
    }
    /*************************************************************************************
    Method Name             testhandler_upsertBillSchedulesOnMilestone_noRelatedRecords
    Test Purpose            upsertBillSchedulesOnMilestone test case
                            upsertBillSchedulesOnMilestone method from the class
    *************************************************************************************/
    @isTest
    static void testhandler_upsertBillSchedulesOnMilestone_noRelatedRecords(){
        //Now inserting the quote as the sales user
        User financeUser = [SELECT ID,Name from User WHERE Lastname='FinanceUserTesting' LIMIT 1];

        //System.runAs(financeUser){
            //Opportunity is already inserted.
            //Querying the opportunity
            Opportunity test_opp = [SELECT ID from Opportunity LIMIT 1];
            //Querying the pricebook
            list<PricebookEntry> list_priceBookEntry = [SELECT Id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Pricebook2.name='Test Class pricebook'];
            System.debug('Queried Opportuinty as Finance >>>> ' + test_opp);
            Project__c inst_newProject = new Project__c(
                                                            Name='secondProjectForOpportunity',
                                                            Opportunity__c = test_opp.Id,
                                                            PO_Date__c = System.today(),
                                                            Contract_Date__c = System.today(),
                                                            HW_delivery_Date__c = System.today(),
                                                            HW_Install_Date__c = System.today(),
                                                            SW_delivery_Date__c = System.today(),
                                                            RFA_Date__c = System.today(),
                                                            UAT_Date__c = System.today(),
                                                            Stability_Date__c = System.today(),
                                                            FA_Date__c = System.today(),
                                                            KPI_Date__c = System.today(),
                                                            Retention_Date__c = System.today()
                                                        );
            System.debug('Before insert project  >>>> ' + inst_newProject);
            insert inst_newProject;
            System.debug('Before insert project  >>>> ' + inst_newProject);
            //Querying the milestones related to the opportunity
            list<Milestone__c> testList_Milestone = [SELECT ID,Project__c,ProductCategory__c  from Milestone__c WHERE Project__c =:inst_newProject.id];
            //Asserting if there are 7 milestones created
            System.assertEquals(7, testList_Milestone.size());

            //creating the running Billing schedule record
            list<Schedule__c> list_schedules = new list<Schedule__c>();
            Schedule__c running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id1';
            running_schedule.Project__c                     = inst_newProject.Id;
            running_schedule.Milestone_name__c              = 'PO';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = inst_newProject.Id;
            running_schedule.Milestone_name__c              = 'Contract';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = inst_newProject.Id;
            running_schedule.Milestone_name__c              = 'HW Delivery';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = inst_newProject.Id;
            running_schedule.Milestone_name__c              = 'HW Install';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = inst_newProject.Id;
            running_schedule.Milestone_name__c              = 'SW Delivery';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = inst_newProject.Id;
            running_schedule.Milestone_name__c              = 'FA';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = inst_newProject.Id;
            running_schedule.Milestone_name__c              = 'RFA';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = inst_newProject.Id;
            running_schedule.Milestone_name__c              = 'UAT';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = inst_newProject.Id;
            running_schedule.Milestone_name__c              = 'Stability';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = inst_newProject.Id;
            running_schedule.Milestone_name__c              = 'KPI';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = inst_newProject.Id;
            running_schedule.Milestone_name__c              = 'Retention';
            list_schedules.add(running_schedule);

            insert list_schedules;


            //Calling the method
            clsHandler_billingSchedule_project inst_clsHandler_billingSchedule_project = new clsHandler_billingSchedule_project();
            inst_clsHandler_billingSchedule_project.upsertBillSchedulesOnMilestone(testList_Milestone);

       // }
    }
    /*************************************************************************************
    Method Name             testhandler_upsertBillSchedulesOnMilestone_priorSchedules
    Test Purpose            upsertBillSchedulesOnMilestone test case
                            upsertBillSchedulesOnMilestone method from the class
    *************************************************************************************/
    @isTest
    static void testhandler_upsertBillSchedulesOnMilestone_priorSchedules_changeInDates(){
        //
        //Now inserting the quote as the sales user
        User salesUser = [SELECT ID,Name from User WHERE Lastname='SalesUserTesting1' LIMIT 1];
        System.runAs(salesUser){
            //Opportunity is already inserted.
            //Querying the opportunity
            Opportunity test_opp = [SELECT ID from Opportunity LIMIT 1];
            //Querying the pricebook
            list<PricebookEntry> list_priceBookEntry = [SELECT Id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Pricebook2.name='Test Class pricebook'];
            test_opp.Pricebook2Id = list_priceBookEntry[0].Pricebook2Id;
            update test_opp;
            //getting the project Id
            clshandler_milestone_schedule.fetchProjectForOpportunityId((string)test_opp.Id);
            //Getting milestone headers
            clshandler_milestone_schedule.fetchMilestoneHeaders();
            //Getting the project and related milestones
            Project__c relatedProject = [SELECT Id,FA_Date__c FROM Project__c WHERE Opportunity__c=:test_opp.id LIMIT 1];
            //Using Aura handler to get the project details
            Project__c completeProjectWithDetails = clshandler_milestone_schedule.fetchProjectDetails(relatedProject.id);
            completeProjectWithDetails.PO_Date__c = System.today();
            completeProjectWithDetails.Contract_Date__c = System.today();
            completeProjectWithDetails.HW_delivery_Date__c = System.today();
            completeProjectWithDetails.HW_Install_Date__c = System.today();
            completeProjectWithDetails.SW_delivery_Date__c = System.today();
            completeProjectWithDetails.RFA_Date__c = System.today();
            completeProjectWithDetails.UAT_Date__c = System.today();
            completeProjectWithDetails.Stability_Date__c = System.today();
            completeProjectWithDetails.FA_Date__c = System.today();
            //completeProjectWithDetails.KPI_Date__c =null;
            completeProjectWithDetails.Retention_Date__c = System.today();

            //Getting the milestones
            list<Milestone__c> list_relatedMilestones = new list<Milestone__c>();
            list_relatedMilestones = clshandler_milestone_schedule.fetchMilestoneRows(relatedProject.Id);
            for(Milestone__c iterating_milestone: list_relatedMilestones){
                    iterating_milestone.PO__c = 10;
                    iterating_milestone.Contract__c = 10;
                    iterating_milestone.HW_delivery__c = 10;
                    iterating_milestone.HW_install__c = 10;
                    iterating_milestone.SW_delivery__c = 10;
                    iterating_milestone.RFA__c = 10;
                    iterating_milestone.UAT__c = 10;
                    iterating_milestone.Stability__c = 10;
                    iterating_milestone.FA__c = 10;
                    iterating_milestone.KPI__c = 5;
                    iterating_milestone.Retention__c = 5;
            }
            //Save method
            clshandler_milestone_schedule.saveMethod(completeProjectWithDetails, list_relatedMilestones);

            //creating the running Billing schedule record
            list<Schedule__c> list_schedules = new list<Schedule__c>();
            Schedule__c running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW';
            running_schedule.Product__c                     = list_priceBookEntry[0].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id1';
            running_schedule.Project__c                     = completeProjectWithDetails.Id;
            running_schedule.Milestone_name__c              = 'PO';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = completeProjectWithDetails.Id;
            running_schedule.Milestone_name__c              = 'FA';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[1].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = completeProjectWithDetails.Id;
            running_schedule.Milestone_name__c              = 'FA';
            list_schedules.add(running_schedule);

            insert list_schedules;

            //inserting quote line items
            list<OpportunityLineItem> list_oppLineItem = new list<OpportunityLineItem>();
            OpportunityLineItem iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[0].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 7500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Milestone',
                                                                            Project__c =completeProjectWithDetails.Id
                                                                        );
            list_oppLineItem.add(iterating_lineItem);
            iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[0].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 4500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Milestone',
                                                                            Project__c =completeProjectWithDetails.Id
                                                                        );
            list_oppLineItem.add(iterating_lineItem);
            iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[0].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 4500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Milestone',
                                                                            Project__c =completeProjectWithDetails.Id
                                                                        );
            list_oppLineItem.add(iterating_lineItem);
            //inserting opp line items
             iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[0].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 9500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Monthly',
                                                                            Project__c =completeProjectWithDetails.Id,
                                                                            MBIL_Effective_Start_date__c = System.today(),
                                                                            MBIL_Subscription_Term__c =12
                                                                        );
            list_oppLineItem.add(iterating_lineItem);

            //inserting opp line items
             iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[0].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 7500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'One-Time',
                                                                            Project__c =completeProjectWithDetails.Id,
                                                                            MBIL_Effective_Start_date__c = System.today()
                                                                        );
            list_oppLineItem.add(iterating_lineItem);

            insert list_oppLineItem;

            //Now changing Dates
            completeProjectWithDetails.PO_Date__c = null;
            update completeProjectWithDetails;

            update list_relatedMilestones;

        }
    }
    /*************************************************************************************
    Method Name             testhandler_upsertBillSchedulesOnMilestone_priorSchedules
    Test Purpose            upsertBillSchedulesOnMilestone test case
                            upsertBillSchedulesOnMilestone method from the class
    *************************************************************************************/
    @isTest
    static void testhandler_upsertBillSchedulesOnMilestone_priorSchedules(){
        //
        //Now inserting the quote as the sales user
        User salesUser = [SELECT ID,Name from User WHERE Lastname='SalesUserTesting1' LIMIT 1];
        System.runAs(salesUser){
            //Opportunity is already inserted.
            //Querying the opportunity
            Opportunity test_opp = [SELECT ID,Pricebook2Id from Opportunity LIMIT 1];

            //Querying the pricebook
            list<PricebookEntry> list_priceBookEntry = [SELECT Id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Pricebook2.name='Test Class pricebook'];
            test_opp.Pricebook2Id = list_priceBookEntry[0].Pricebook2Id;
            update test_opp;
            System.debug('******************' + list_priceBookEntry);
            //getting the project Id
            clshandler_milestone_schedule.fetchProjectForOpportunityId((string)test_opp.Id);
            //Getting milestone headers
            clshandler_milestone_schedule.fetchMilestoneHeaders();
            //Getting the project and related milestones
            Project__c relatedProject = [SELECT Id,FA_Date__c FROM Project__c WHERE Opportunity__c=:test_opp.id LIMIT 1];
            //Using Aura handler to get the project details
            Project__c completeProjectWithDetails = clshandler_milestone_schedule.fetchProjectDetails(relatedProject.id);
            completeProjectWithDetails.PO_Date__c = System.today();
            completeProjectWithDetails.Contract_Date__c = System.today();
            completeProjectWithDetails.HW_delivery_Date__c = System.today();
            completeProjectWithDetails.HW_Install_Date__c = System.today();
            completeProjectWithDetails.SW_delivery_Date__c = System.today();
            completeProjectWithDetails.RFA_Date__c = System.today();
            completeProjectWithDetails.UAT_Date__c = System.today();
            completeProjectWithDetails.Stability_Date__c = System.today();
            completeProjectWithDetails.FA_Date__c = System.today();
            completeProjectWithDetails.KPI_Date__c = System.today();
            completeProjectWithDetails.Retention_Date__c = System.today();

            //Getting the milestones
            list<Milestone__c> list_relatedMilestones = new list<Milestone__c>();
            list_relatedMilestones = clshandler_milestone_schedule.fetchMilestoneRows(relatedProject.Id);
            for(Milestone__c iterating_milestone: list_relatedMilestones){
                    iterating_milestone.PO__c = 10;
                    iterating_milestone.Contract__c = 10;
                    iterating_milestone.HW_delivery__c = 10;
                    iterating_milestone.HW_install__c = 10;
                    iterating_milestone.SW_delivery__c = 10;
                    iterating_milestone.RFA__c = 10;
                    iterating_milestone.UAT__c = 10;
                    iterating_milestone.Stability__c = 10;
                    iterating_milestone.FA__c = 10;
                    iterating_milestone.KPI__c = 5;
                    iterating_milestone.Retention__c = 5;
            }
            //Save method
            clshandler_milestone_schedule.saveMethod(completeProjectWithDetails, list_relatedMilestones);

            //creating the running Billing schedule record
            list<Schedule__c> list_schedules = new list<Schedule__c>();
            Schedule__c running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW';
            running_schedule.Product__c                     = list_priceBookEntry[0].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id1';
            running_schedule.Project__c                     = completeProjectWithDetails.Id;
            running_schedule.Milestone_name__c              = 'PO';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[0].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = completeProjectWithDetails.Id;
            running_schedule.Milestone_name__c              = 'FA';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[0].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = completeProjectWithDetails.Id;
            running_schedule.Milestone_name__c              = 'FA';
            list_schedules.add(running_schedule);

            insert list_schedules;

            //inserting quote line items
            list<OpportunityLineItem> list_oppLineItem = new list<OpportunityLineItem>();
            OpportunityLineItem iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[0].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 7500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Milestone',
                                                                            Project__c =completeProjectWithDetails.Id
                                                                        );
            list_oppLineItem.add(iterating_lineItem);
            iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[1].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 4500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Milestone',
                                                                            Project__c =completeProjectWithDetails.Id
                                                                        );
            list_oppLineItem.add(iterating_lineItem);
            iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[0].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 4500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Milestone',
                                                                            Project__c =completeProjectWithDetails.Id
                                                                        );
            list_oppLineItem.add(iterating_lineItem);
            //inserting opp line items
             iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[0].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 9500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Monthly',
                                                                            Project__c =completeProjectWithDetails.Id,
                                                                            MBIL_Effective_Start_date__c = System.today(),
                                                                            MBIL_Subscription_Term__c =12
                                                                        );
            list_oppLineItem.add(iterating_lineItem);

            //inserting opp line items
             iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[1].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 7500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'One-Time',
                                                                            Project__c =completeProjectWithDetails.Id,
                                                                            MBIL_Effective_Start_date__c = System.today()
                                                                        );
            list_oppLineItem.add(iterating_lineItem);

            insert list_oppLineItem;

            update list_OppLineItem[0];
        }
    }
    /*************************************************************************************
    Method Name             testhandler_upsertBillSchedulesOnMilestone_priorSchedules_onlyUAT
    Test Purpose            upsertBillSchedulesOnMilestone test case
                            upsertBillSchedulesOnMilestone method from the class
    *************************************************************************************/
    @isTest
    static void testhandler_upsertBillSchedulesOnMilestone_priorSchedules_onlyUAT(){
        //
        //Now inserting the quote as the sales user
        User salesUser = [SELECT ID,Name from User WHERE Lastname='SalesUserTesting1' LIMIT 1];
        System.runAs(salesUser){
            //Opportunity is already inserted.
            //Querying the opportunity
            Opportunity test_opp = [SELECT ID,Pricebook2Id from Opportunity LIMIT 1];

            //Querying the pricebook
            list<PricebookEntry> list_priceBookEntry = [SELECT Id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Pricebook2.name='Test Class pricebook'];
            test_opp.Pricebook2Id = list_priceBookEntry[0].Pricebook2Id;
            update test_opp;
            System.debug('******************' + list_priceBookEntry);
            //getting the project Id
            clshandler_milestone_schedule.fetchProjectForOpportunityId((string)test_opp.Id);
            //Getting milestone headers
            clshandler_milestone_schedule.fetchMilestoneHeaders();
            //Getting the project and related milestones
            Project__c relatedProject = [SELECT Id,FA_Date__c FROM Project__c WHERE Opportunity__c=:test_opp.id LIMIT 1];
            //Using Aura handler to get the project details
            Project__c completeProjectWithDetails = clshandler_milestone_schedule.fetchProjectDetails(relatedProject.id);
            completeProjectWithDetails.UAT_Date__c = System.today();

            //Getting the milestones
            list<Milestone__c> list_relatedMilestones = new list<Milestone__c>();
            list_relatedMilestones = clshandler_milestone_schedule.fetchMilestoneRows(relatedProject.Id);
            for(Milestone__c iterating_milestone: list_relatedMilestones){
                    iterating_milestone.UAT__c = 100;
            }
            //Save method
            clshandler_milestone_schedule.saveMethod(completeProjectWithDetails, list_relatedMilestones);

            //creating the running Billing schedule record
            list<Schedule__c> list_schedules = new list<Schedule__c>();
            Schedule__c running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW';
            running_schedule.Product__c                     = list_priceBookEntry[0].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id1';
            running_schedule.Project__c                     = completeProjectWithDetails.Id;
            running_schedule.Milestone_name__c              = 'PO';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[0].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = completeProjectWithDetails.Id;
            running_schedule.Milestone_name__c              = 'FA';
            list_schedules.add(running_schedule);

            running_schedule = new Schedule__c();
            running_schedule.Amount__c                      = 1;
            running_schedule.Scheduled_Date__c              = System.today();
            running_schedule.Opportunity__c                 = test_opp.Id;
            running_schedule.Billing_Frequency__c           = 'Monthly';
            running_schedule.Product_Category__c            = 'MBLIM SW MNT';
            running_schedule.Product__c                     = list_priceBookEntry[0].Product2Id;
            running_schedule.Opportunity_Line_Item_ID__c    = 'test opp id2';
            running_schedule.Project__c                     = completeProjectWithDetails.Id;
            running_schedule.Milestone_name__c              = 'UAT';
            list_schedules.add(running_schedule);

            insert list_schedules;

            //inserting quote line items
            list<OpportunityLineItem> list_oppLineItem = new list<OpportunityLineItem>();
            OpportunityLineItem iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[0].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 7500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Milestone',
                                                                            Project__c =completeProjectWithDetails.Id
                                                                        );
            list_oppLineItem.add(iterating_lineItem);
            iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[1].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 4500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Milestone',
                                                                            Project__c =completeProjectWithDetails.Id
                                                                        );
            list_oppLineItem.add(iterating_lineItem);
            iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[0].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 4500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Milestone',
                                                                            Project__c =completeProjectWithDetails.Id
                                                                        );
            list_oppLineItem.add(iterating_lineItem);
            //inserting opp line items
             iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[0].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 9500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'Monthly',
                                                                            Project__c =completeProjectWithDetails.Id,
                                                                            MBIL_Effective_Start_date__c = System.today(),
                                                                            MBIL_Subscription_Term__c =12
                                                                        );
            list_oppLineItem.add(iterating_lineItem);

            //inserting opp line items
             iterating_lineItem = new OpportunityLineItem(
                                                                            opportunityId = test_opp.Id,
                                                                            pricebookentryId = list_priceBookEntry[1].Id,
                                                                            Quantity = 1,
                                                                            UnitPrice = 7500,
                                                                            Description = 'TestOppLineItems',
                                                                            MBLM_Billing_Frequency__c = 'One-Time',
                                                                            Project__c =completeProjectWithDetails.Id,
                                                                            MBIL_Effective_Start_date__c = System.today()
                                                                        );
            list_oppLineItem.add(iterating_lineItem);

            insert list_oppLineItem;
            Test.startTest();
            //Changing the amount
                list_OppLineItem[0].UnitPrice = 10000;
                update list_OppLineItem[0];

                //deleting the opportunity
                delete  list_OppLineItem[0];
            Test.stopTest();
        }
    }
    
    @isTest
    static void coverage(){
        clshandler_billingSchedule_project.coverage();
    }
}