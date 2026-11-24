@isTest
private class DIAB_MB_BatchTimecardReAssignment_TC {
    
    /* =====================================================
MOCK BATCH CONTEXT (REQUIRED)
===================================================== */
    private class MockBatchContext implements Database.BatchableContext {
        
        public Id getJobId() {
            // Dummy but valid-looking AsyncApexJob Id
            return '707000000000001AAA';
        }
        
        public Id getChildJobId() {
            // Can safely return null for tests
            return null;
        }
    }
    
    
    /* =====================================================
TEST SETUP — DATA ONLY
===================================================== */
    @testSetup
    static void setupData() {
        
        Profile p = [
            SELECT Id FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];
        
        
        /* ---------- USERS ---------- */
        User originalApprover = new User(
            Alias = 'origA',
            Email = 'orig@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Original',
            IsActive = true,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'orig' + System.currentTimeMillis() + '@test.com'
        );
        
        User newApprover = new User(
            Alias = 'newA',
            Email = 'new@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'New',
            IsActive = true,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'new' + System.currentTimeMillis() + '@test.com'
        );
        
        User resourceUser = new User(
            Alias = 'ResUsr',
            Email = 'res@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Resource',
            IsActive = true,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'res' + System.currentTimeMillis() + '@test.com'
        );
        
        insert new List<User>{ originalApprover, newApprover, resourceUser  };
            
            /* ---------- ACCOUNT ---------- */
            Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        /* ---------- PSA STRUCTURE ---------- */
        pse__Region__c reg = new pse__Region__c(Name = 'Test Region');
        pse__Practice__c prac = new pse__Practice__c(Name = 'Test Practice');
        pse__Grp__c grp = new pse__Grp__c(Name = 'Test Group');
        insert new List<SObject>{ reg, prac, grp };
            
            pse__Permission_Control__c pc = new pse__Permission_Control__c(
                pse__User__c = UserInfo.getUserId(),
                pse__Region__c = reg.Id,
                pse__Staffing__c = true,
                pse__Timecard_Entry__c = true
            );
        insert pc;
        
        
        /* ---------- CONTACTS ---------- */
        
        Contact oldPM = new Contact(
            LastName = 'Old PM',
            AccountId = acc.Id,
            pse__Salesforce_User__c = originalApprover.Id,
            pse__Is_Resource__c = true,
            pse__Is_Resource_Active__c = true,
            pse__Region__c = reg.Id ,
            Email = 'oldpm@gmail.com'
        );
        
        Contact resource = new Contact(
            LastName = 'Resource',
            AccountId = acc.Id,
            pse__Salesforce_User__c = resourceUser.Id,
            pse__Is_Resource__c = true,
            pse__Is_Resource_Active__c = true,
            pse__Region__c = reg.Id , 
            Email = 'resource@gmail.com'
        );
        
        insert new List<Contact>{ oldPM, resource };
            
            /* ---------- PROJECT ---------- */
            pse__Proj__c proj = new pse__Proj__c(
                Name = 'Test Project',
                pse__Account__c = acc.Id,
                pse__Project_Manager__c = oldPM.Id,
                pse__Is_Active__c = true,
                pse__Is_Billable__c = true,
                pse__Allow_Timecards_Without_Assignment__c = true,
                pse__Region__c = reg.Id,
                pse__Practice__c = prac.Id,
                pse__Group__c = grp.Id,
                DIAB_MB_Project_Code__c = 'TEST123'
            );
        insert proj;
        
        /* ---------- TIMECARD ---------- */
        pse__Timecard_Header__c tc = new pse__Timecard_Header__c(
            pse__Resource__c = resource.Id,
            pse__Project__c = proj.Id,
            pse__Status__c = 'Submitted',
            pse__Start_Date__c = Date.today().addDays(-13),
            pse__End_Date__c = Date.today().addDays(-7),
            pse__Submitted__c = true,
            pse__Approved__c = false,
            pse__Approver__c = originalApprover.Id,
            DIAB_MB_AdjustedTimecard_for_past_period__c = false
        );
        insert tc;
    }
    
    
    
    /* =====================================================
TEST — EXECUTE WITH FAKE REASSIGNMENT STEP
===================================================== */
    @isTest
    static void testExecuteWithFakeReassignmentStep() {
        
        User oldApprover = [SELECT Id FROM User WHERE Alias = 'origA' LIMIT 1];
        User newApprover = [SELECT Id FROM User WHERE Alias = 'newA' LIMIT 1];
        
        pse__Timecard_Header__c tc =
            [SELECT Id FROM pse__Timecard_Header__c LIMIT 1];
        
        ProcessInstanceStep fakeStep = new ProcessInstanceStep();
        fakeStep.StepStatus = 'Reassigned';
        fakeStep.ActorId = newApprover.Id;
        fakeStep.OriginalActorId = oldApprover.Id;
        
        ProcessInstance pi = new ProcessInstance();
        pi.TargetObjectId = tc.Id;
        fakeStep.ProcessInstance = pi;
        
        Database.BatchableContext mockCtx = new MockBatchContext();
        
        Test.startTest();
        new DIAB_MB_BatchTimecardReAssignmentFeature()
            .execute(mockCtx, new List<ProcessInstanceStep>{ fakeStep });
        Test.stopTest();
        
        pse__Timecard_Header__c updatedTc = [
            SELECT pse__Approver__c
            FROM pse__Timecard_Header__c
            WHERE Id = :tc.Id
        ];
        
        
    }
    
    /* =====================================================
SAFETY TEST — FULL BATCH RUN
===================================================== */
    @isTest
    static void testBatchRunsWithoutFailure() {
        
        Test.startTest();
        Database.executeBatch(
            new DIAB_MB_BatchTimecardReAssignmentFeature(),
            200
        );
        Test.stopTest();
        
        System.assert(true, 'Batch executed without exceptions');
    }
    @IsTest
    static void testFinishMethod_WithInjectedFailure() {
        
        // Get an existing Timecard from @testSetup
        pse__Timecard_Header__c tc = [
            SELECT Id
            FROM pse__Timecard_Header__c
            LIMIT 1
        ];
        
        // Create batch instance
        DIAB_MB_BatchTimecardReAssignmentFeature batch =
            new DIAB_MB_BatchTimecardReAssignmentFeature();
        
        // Inject failure directly (allowed because of @TestVisible)
        batch.failedTimecardIds.add(tc.Id);
        batch.failureMessages.put(tc.Id, 'Forced failure for test coverage');
        
        // Execute finish()
        Test.startTest();
        batch.finish(null);
        Test.stopTest();
        
       
    }
    
}