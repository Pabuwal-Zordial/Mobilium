@istest
private class TestBDMChangeOpptyTeam {
    
    static testmethod void unittest (){
        Profile salesUserProfile = [SELECT Id FROM Profile WHERE Name='Mobileum - Sales User'];
        User salesUser_1 = new User(Alias = 'standt', Email='standarduser@mbil1212.com',
           EmailEncodingKey='UTF-8', LastName='SalesUserTesting1', LanguageLocaleKey='en_US',
           LocaleSidKey='en_US', ProfileId = salesUserProfile.Id,
           TimeZoneSidKey='America/Los_Angeles', UserName='standarduser12234@mbil1212.com');
            insert salesUser_1;
      Pricebook2 inst_priceBook = new Pricebook2();
           inst_priceBook = new Pricebook2(Name = 'Test Class pricebook', Description = 'Test Class pricebook', IsActive = true );
            insert inst_priceBook;
           Currency_Table__c inst_Currency_Table = new Currency_Table__c();
           inst_Currency_Table = new Currency_Table__c(
                                                            Name = 'INR',
                                                            Conversion_Rate__c = 0.15
                                                            );
          
           //DML - currency
           insert inst_Currency_Table;

           
           Account a = new Account();
           a.name = 'Test Account';
           insert a; 
                 Opportunity test_opportunity = new Opportunity(AccountId=a.Id,
                                                               Name = 'Test Opportunity',
                                                               StageName = 'Develop Solution',
                                                               Forecast_Category__c = 'Commit',
                                                               CloseDate=System.today(),
                                                               Probability_to_Close_Picklist__c = '0%',
                                                               Type='TL-Term License',
                                                               Amount = 0.00,
                                                               Pricebook2Id = inst_priceBook.id,
                                                               Currency_Table__c = inst_Currency_Table.id ,
                                                               Business_Unit__c = 'Risk',
                                                               Revenue_Assurance_Booking_Value_QC__c = 10,
                                                               Current_Quarter_Billing__c =100,
                                                               Cross_sell1__c='Upsell',
                                                               Forecasted_ACV_Amount_QC__c=0
                                                               );
            insert test_opportunity;    
        
        OpportunityTeamMember OTM = new OpportunityTeamMember ( OpportunityId=test_opportunity.Id, 
                                                               TeamMemberRole   ='Business Development Manager',
                                                                OpportunityAccessLevel='Read',
                                                              UserId=salesUser_1.Id);
            Insert OTM;
        
        OpportunityTeamMember OTM1 = [SELECT Id, TeamMemberRole  FROM OpportunityTeamMember WHERE Id = :OTM.Id LIMIT 1];
        String Role='Account Manager';
        OTM1.TeamMemberRole=Role;
        Update OTM1;
        
    }

    @isTest
    static void itShouldVerifyUniqueOpportunityRolePerOpportunity ()
    {
        Profile salesUserProfile = [SELECT Id FROM Profile WHERE Name='Mobileum - Super Sales User'];

        List<User> userList = new List<User>();

        for (Integer i = 0, j = 0; i < 30; i++) {
            User testUser = new User();
            testUser.Alias = 'standt' + i;
            testUser.Email = 'standarduser' + i + '@mbil1212.com';
            testUser.EmailEncodingKey='UTF-8';
            testUser.LastName='SalesUserTesting1'+ i;
            testUser.LanguageLocaleKey='en_US';
            testUser.LocaleSidKey='en_US';
            testUser.ProfileId = salesUserProfile.Id;
            testUser.TimeZoneSidKey='America/Los_Angeles';
            testUser.UserName='standarduser12234' + i + '@mbil1212.com';
            userList.add(testUser);
        }
        insert userList;

        Account testAccount = new Account();
        testAccount.Name = 'testAccount';
        insert testAccount;

        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'testOpportunity';
        testOpportunity.AccountId = testAccount.Id;
        //testOpportunity.StageName = 'Proposal';
        testOpportunity.CloseDate = System.today();
        testOpportunity.Probability_to_Close_Picklist__c = '0%';
        testOpportunity.Type='TL-Term License';
        testOpportunity.Business_Unit__c = 'Risk';
        testOpportunity.StageName = 'Develop Solution';
        testOpportunity.Forecast_Category__c = 'Commit';
        testOpportunity.Revenue_Assurance_Booking_Value_QC__c = 10;
        testOpportunity.Current_Quarter_Billing__c =100;
        testOpportunity.Cross_sell1__c='Upsell';
        testOpportunity.Forecasted_ACV_Amount_QC__c=0;

        insert testOpportunity;

        List<OpportunityTeamMember> testOppTeamMemberList = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> testOppTeamMemberListb = new List<OpportunityTeamMember>();
        
        OpportunityTeamMember testOpportunityTeamMember1 = new OpportunityTeamMember();
        testOpportunityTeamMember1.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember1.TeamMemberRole = 'Technical Account Manager';
        testOpportunityTeamMember1.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember1.UserId = userList[0].Id;
        testOppTeamMemberList.add(testOpportunityTeamMember1);

        OpportunityTeamMember testOpportunityTeamMember2 = new OpportunityTeamMember();
        testOpportunityTeamMember2.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember2.TeamMemberRole = 'Additional Technical Account Manager';
        testOpportunityTeamMember2.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember2.UserId = userList[1].Id;
        testOppTeamMemberList.add(testOpportunityTeamMember2);

        OpportunityTeamMember testOpportunityTeamMember4 = new OpportunityTeamMember();
        testOpportunityTeamMember4.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember4.TeamMemberRole = 'CRO';
        testOpportunityTeamMember4.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember4.UserId = userList[3].Id;
        testOppTeamMemberList.add(testOpportunityTeamMember4);

        OpportunityTeamMember testOpportunityTeamMember5 = new OpportunityTeamMember();
        testOpportunityTeamMember5.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember5.TeamMemberRole = 'Global TAM';
        testOpportunityTeamMember5.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember5.UserId = userList[4].Id;
        testOppTeamMemberList.add(testOpportunityTeamMember5);

        OpportunityTeamMember testOpportunityTeamMember6 = new OpportunityTeamMember();
        testOpportunityTeamMember6.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember6.TeamMemberRole = 'General Manager';
        testOpportunityTeamMember6.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember6.UserId = userList[5].Id;
        testOppTeamMemberList.add(testOpportunityTeamMember6);

        OpportunityTeamMember testOpportunityTeamMember7 = new OpportunityTeamMember();
        testOpportunityTeamMember7.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember7.TeamMemberRole = 'Overlay';
        testOpportunityTeamMember7.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember7.UserId = userList[6].Id;
        testOppTeamMemberList.add(testOpportunityTeamMember7);

        OpportunityTeamMember testOpportunityTeamMember8 = new OpportunityTeamMember();
        testOpportunityTeamMember8.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember8.TeamMemberRole = 'Business Development Manager';
        testOpportunityTeamMember8.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember8.UserId = userList[7].Id;
        testOppTeamMemberList.add(testOpportunityTeamMember8);

        OpportunityTeamMember testOpportunityTeamMember1b = new OpportunityTeamMember();
        testOpportunityTeamMember1b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember1b.TeamMemberRole = 'Overlay 2';
        testOpportunityTeamMember1b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember1b.UserId = userList[8].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember1b);

        OpportunityTeamMember testOpportunityTeamMember2b = new OpportunityTeamMember();
        testOpportunityTeamMember2b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember2b.TeamMemberRole = 'Overlay 3';
        testOpportunityTeamMember2b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember2b.UserId = userList[9].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember2b);

        OpportunityTeamMember testOpportunityTeamMember4b = new OpportunityTeamMember();
        testOpportunityTeamMember4b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember4b.TeamMemberRole = 'Overlay 4';
        testOpportunityTeamMember4b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember4b.UserId = userList[10].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember4b);

        OpportunityTeamMember testOpportunityTeamMember5b = new OpportunityTeamMember();
        testOpportunityTeamMember5b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember5b.TeamMemberRole = 'Overlay 5';
        testOpportunityTeamMember5b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember5b.UserId = userList[11].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember5b);

        OpportunityTeamMember testOpportunityTeamMember6b = new OpportunityTeamMember();
        testOpportunityTeamMember6b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember6b.TeamMemberRole = 'Overlay 6';
        testOpportunityTeamMember6b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember6b.UserId = userList[12].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember6b);

        OpportunityTeamMember testOpportunityTeamMember7b = new OpportunityTeamMember();
        testOpportunityTeamMember7b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember7b.TeamMemberRole = 'BU Overlay';
        testOpportunityTeamMember7b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember7b.UserId = userList[13].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember7b);

        OpportunityTeamMember testOpportunityTeamMember8b = new OpportunityTeamMember();
        testOpportunityTeamMember8b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember8b.TeamMemberRole = 'Renewal Specialist';
        testOpportunityTeamMember8b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember8b.UserId = userList[14].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember8b);
        
        OpportunityTeamMember testOpportunityTeamMember9b= new OpportunityTeamMember();
        testOpportunityTeamMember9b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember9b.TeamMemberRole = 'Solution Architect';
        testOpportunityTeamMember9b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember9b.UserId = userList[15].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember9b);
        
        OpportunityTeamMember testOpportunityTeamMember10b= new OpportunityTeamMember();
        testOpportunityTeamMember10b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember10b.TeamMemberRole = 'Business Unit Lead Roaming';
        testOpportunityTeamMember10b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember10b.UserId = userList[16].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember10b);

        OpportunityTeamMember testOpportunityTeamMember11b= new OpportunityTeamMember();
        testOpportunityTeamMember11b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember11b.TeamMemberRole = 'Business Unit Lead Testing';
        testOpportunityTeamMember11b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember11b.UserId = userList[17].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember11b);
        
        OpportunityTeamMember testOpportunityTeamMember12b= new OpportunityTeamMember();
        testOpportunityTeamMember12b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember12b.TeamMemberRole = 'Overlay 2';
        testOpportunityTeamMember12b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember12b.UserId = userList[18].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember12b);
        
        OpportunityTeamMember testOpportunityTeamMember13b= new OpportunityTeamMember();
        testOpportunityTeamMember13b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember13b.TeamMemberRole = 'Overlay 3';
        testOpportunityTeamMember13b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember13b.UserId = userList[19].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember13b);
        
        OpportunityTeamMember testOpportunityTeamMember14b= new OpportunityTeamMember();
        testOpportunityTeamMember14b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember14b.TeamMemberRole = 'Overlay 4';
        testOpportunityTeamMember14b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember14b.UserId = userList[20].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember14b);
        
        OpportunityTeamMember testOpportunityTeamMember15b= new OpportunityTeamMember();
        testOpportunityTeamMember15b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember15b.TeamMemberRole = 'Overlay 5';
        testOpportunityTeamMember15b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember15b.UserId = userList[21].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember15b);
        
        OpportunityTeamMember testOpportunityTeamMember16b= new OpportunityTeamMember();
        testOpportunityTeamMember16b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember16b.TeamMemberRole = 'Overlay 7';
        testOpportunityTeamMember16b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember16b.UserId = userList[22].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember16b);
        
        OpportunityTeamMember testOpportunityTeamMember17b= new OpportunityTeamMember();
        testOpportunityTeamMember17b.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember17b.TeamMemberRole = 'Overlay 9';
        testOpportunityTeamMember17b.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember17b.UserId = userList[23].Id;
        testOppTeamMemberListb.add(testOpportunityTeamMember17b);
        
        insert testOppTeamMemberList;

        Test.startTest();
        Database.SaveResult[] srList = Database.insert(testOppTeamMemberListb, false);
        Test.stopTest();
        //TO:DO System Assert
    }
    @isTest
    static void itShouldVerifyDeleteBusinessManager ()
    {
        Profile salesUserProfile = [SELECT Id FROM Profile WHERE Name='Mobileum - Super Sales User'];

        List<User> userList = new List<User>();

        User testUser = new User();
        testUser.Alias = 'standt';
        testUser.Email = 'standarduser@mbil1212.com';
        testUser.EmailEncodingKey='UTF-8';
        testUser.LastName='SalesUserTesting1';
        testUser.LanguageLocaleKey='en_US';
        testUser.LocaleSidKey='en_US';
        testUser.ProfileId = salesUserProfile.Id;
        testUser.TimeZoneSidKey='America/Los_Angeles';
        testUser.UserName='standarduser12234@mbil1212.com';

        userList.add(testUser);

        User testUser2 = new User();
        testUser2.Alias = 'standt';
        testUser2.Email = 'standarduser@mbil1212.com';
        testUser2.EmailEncodingKey='UTF-8';
        testUser2.LastName='SalesUserTesting1';
        testUser2.LanguageLocaleKey='en_US';
        testUser2.LocaleSidKey='en_US';
        testUser2.ProfileId = salesUserProfile.Id;
        testUser2.TimeZoneSidKey='America/Los_Angeles';
        testUser2.UserName='standarduser12345@mbil1212.com';
        
        userList.add(testUser2);

        insert userList;


        Account testAccount = new Account();
        testAccount.Name = 'testAccount';
        insert testAccount;

        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'testOpportunity';
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.CloseDate = System.today();
        testOpportunity.Probability_to_Close_Picklist__c = '0%';
        testOpportunity.Type='TL-Term License';
        testOpportunity.Business_Unit__c = 'Risk';
        testOpportunity.StageName = 'Develop Solution';
        testOpportunity.Forecast_Category__c = 'Commit';
        testOpportunity.Revenue_Assurance_Booking_Value_QC__c = 10;
        testOpportunity.Current_Quarter_Billing__c =100;
        testOpportunity.Cross_sell1__c='Upsell';
        testOpportunity.Forecasted_ACV_Amount_QC__c=0;
        
        insert testOpportunity; 

        List<OpportunityTeamMember> opportunityTeamMemberList = new List<OpportunityTeamMember>();

        OpportunityTeamMember testOpportunityTeamMember = new OpportunityTeamMember();
        testOpportunityTeamMember.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember.TeamMemberRole = 'Senior General Manager';
        testOpportunityTeamMember.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember.UserId = testUser.Id;
        opportunityTeamMemberList.add(testOpportunityTeamMember);

        OpportunityTeamMember testOpportunityTeamMember2 = new OpportunityTeamMember();
        testOpportunityTeamMember2.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember2.TeamMemberRole = 'Business Development Manager';
        testOpportunityTeamMember2.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember2.UserId = testUser2.Id;
        opportunityTeamMemberList.add(testOpportunityTeamMember2);

        insert opportunityTeamMemberList;

        Test.startTest();
        try 
        {
            List<OpportunitySplit> osList = [SELECT ID, SplitOwnerId, SplitOwner.Name FROM OpportunitySplit WHERE SplitOwnerId = :testUser2.Id];
            delete osList;

            List<OpportunityTeamMember> otmList = [SELECT ID, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId = :testOpportunity.Id AND userId = :testUser2.Id];
            delete otmList;

        } catch (Exception e) {
            
        }
        Test.stopTest();
        //TO:DO System Assert
    }

    @isTest
    static void itShouldVerifyDuplicateTeamMemberRole ()
    {
        Profile salesUserProfile = [SELECT Id FROM Profile WHERE Name='Mobileum - Super Sales User'];

        List<User> userList = new List<User>();

        User testUser = new User();
        testUser.Alias = 'standt';
        testUser.Email = 'standarduser@mbil1212.com';
        testUser.EmailEncodingKey='UTF-8';
        testUser.LastName='SalesUserTesting1';
        testUser.LanguageLocaleKey='en_US';
        testUser.LocaleSidKey='en_US';
        testUser.ProfileId = salesUserProfile.Id;
        testUser.TimeZoneSidKey='America/Los_Angeles';
        testUser.UserName='standarduser12234@mbil1212.com';

        userList.add(testUser);

        User testUser2 = new User();
        testUser2.Alias = 'standt';
        testUser2.Email = 'standarduser@mbil1212.com';
        testUser2.EmailEncodingKey='UTF-8';
        testUser2.LastName='SalesUserTesting1';
        testUser2.LanguageLocaleKey='en_US';
        testUser2.LocaleSidKey='en_US';
        testUser2.ProfileId = salesUserProfile.Id;
        testUser2.TimeZoneSidKey='America/Los_Angeles';
        testUser2.UserName='standarduser12345@mbil1212.com';
        
        userList.add(testUser2);
        
        User testUser3 = new User();
        testUser3.Alias = 'standtw';
        testUser3.Email = 'standarduser@mbil12122.com';
        testUser3.EmailEncodingKey='UTF-8';
        testUser3.LastName='SalesUserTesting12';
        testUser3.LanguageLocaleKey='en_US';
        testUser3.LocaleSidKey='en_US';
        testUser3.ProfileId = salesUserProfile.Id;
        testUser3.TimeZoneSidKey='America/Los_Angeles';
        testUser3.UserName='standarduser123456@mbil1212.com';
        
        userList.add(testUser3);
        
        User testUser4 = new User();
        testUser4.Alias = 'standtwe';
        testUser4.Email = 'standarduser@mbil121222.com';
        testUser4.EmailEncodingKey='UTF-8';
        testUser4.LastName='SalesUserTesting12';
        testUser4.LanguageLocaleKey='en_US';
        testUser4.LocaleSidKey='en_US';
        testUser4.ProfileId = salesUserProfile.Id;
        testUser4.TimeZoneSidKey='America/Los_Angeles';
        testUser4.UserName='standarduser123456@mbil12122.com';
        
        userList.add(testUser4);

        insert userList;


        Account testAccount = new Account();
        testAccount.Name = 'testAccount';
        insert testAccount;

        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'testOpportunity';
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.StageName = 'Develop Solution';
        testOpportunity.CloseDate = System.today();
        testOpportunity.Probability_to_Close_Picklist__c = '0%';
        testOpportunity.Type='TL-Term License';
        testOpportunity.Business_Unit__c = 'Risk';
        testOpportunity.Forecast_Category__c = 'Commit';
        testOpportunity.Revenue_Assurance_Booking_Value_QC__c = 10;
        testOpportunity.Current_Quarter_Billing__c =100;
        testOpportunity.Cross_sell1__c='Upsell';
        testOpportunity.Forecasted_ACV_Amount_QC__c=0;
        
        insert testOpportunity; 

        List<OpportunityTeamMember> opportunityTeamMemberList = new List<OpportunityTeamMember>();

        OpportunityTeamMember testOpportunityTeamMember = new OpportunityTeamMember();
        testOpportunityTeamMember.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember.TeamMemberRole = 'Overlay 7';
        testOpportunityTeamMember.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember.UserId = testUser.Id;
        opportunityTeamMemberList.add(testOpportunityTeamMember);

        OpportunityTeamMember testOpportunityTeamMember2 = new OpportunityTeamMember();
        testOpportunityTeamMember2.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember2.TeamMemberRole = 'Overlay 7';
        testOpportunityTeamMember2.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember2.UserId = testUser2.Id;
        opportunityTeamMemberList.add(testOpportunityTeamMember2);
        
        OpportunityTeamMember testOpportunityTeamMember3 = new OpportunityTeamMember();
        testOpportunityTeamMember3.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember3.TeamMemberRole = 'General Manager';
        testOpportunityTeamMember3.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember3.UserId = testUser3.Id;
        opportunityTeamMemberList.add(testOpportunityTeamMember3);

        OpportunityTeamMember testOpportunityTeamMember4 = new OpportunityTeamMember();
        testOpportunityTeamMember4.OpportunityId = testOpportunity.Id;
        testOpportunityTeamMember4.TeamMemberRole = 'General Manager';
        testOpportunityTeamMember4.OpportunityAccessLevel = 'Read';
        testOpportunityTeamMember4.UserId = testUser4.Id;
        opportunityTeamMemberList.add(testOpportunityTeamMember4);

        Test.startTest();
        String errorMessage = '';
        String errorMessage1 = '';
        try 
        {
            insert opportunityTeamMemberList;

        } catch (Exception e) {
            errorMessage = e.getMessage();
            errorMessage1 = e.getMessage();
        }
        Test.stopTest();
        System.assert(errorMessage.contains('Overlay 7'));
        //System.assert(errorMessage1.contains('General Manager'));
        //TO:DO System Assert
    }
}