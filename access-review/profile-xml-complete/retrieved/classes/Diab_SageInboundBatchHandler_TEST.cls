@isTest
private class Diab_SageInboundBatchHandler_TEST{
  
    @TestSetup
    static void setupTestData(){
        Diab_Integration_Settings__c integrationSettings = new Diab_Integration_Settings__c();
        integrationSettings.PSA_Resource_Account_Name__c = 'Mobileum, Inc';
        integrationSettings.Sage_Team_Filter_Value__c = 'Global Delivery;Customer Support;Managed Services;Engineering;Product Management;PCC Head;Finance;IT & Systems';
        insert integrationSettings;

        Account testAccount = new Account(Name = 'Mobileum, Inc');
        insert testAccount;
        
        pse__Work_Calendar__c defaultWorkCalendar = new pse__Work_Calendar__c(Name = 'USA-Standard');
        Database.insert(defaultWorkCalendar,false);
    }

    
    
    @isTest
    private static void Diab_SageInboundBatchHandler_TEST() {
        Diab_SageInboundBatchHandler obj = new Diab_SageInboundBatchHandler();
    }
    
    @isTest 
    static void processSageEmployeeRecords_Test() {
        
        Diab_SageUtil.Diab_Sage_Employee testEmployee = new Diab_SageUtil.Diab_Sage_Employee();
        testEmployee.id = 'TestID';
        testEmployee.lastName = 'TestLastName';
        testEmployee.firstName = 'TestFirstName';
        testEmployee.emailAddress = 'test@example.com';
        
        // Add additional fields
        List<Diab_SageUtil.Diab_Sage_AdditionalFields> additionalFields = new List<Diab_SageUtil.Diab_Sage_AdditionalFields>();
        Diab_SageUtil.Diab_Sage_AdditionalFields additionalField = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        additionalField.name = 'Team_FF';
        additionalField.value = 'Active';
        testEmployee.additionalFields = new List<Diab_SageUtil.Diab_Sage_AdditionalFields>{additionalField};
        
        pse__Work_Calendar__c defaultWorkCalendar; 
        try {
            defaultWorkCalendar = [SELECT Id, Name, Work_Day_Patterns__c FROM pse__Work_Calendar__c WHERE Name = 'USA-Standard' LIMIT 1];
        } catch (QueryException e) {
            System.debug('Default work calendar not found: ' + e.getMessage());
            defaultWorkCalendar = null;
        }

        
        Test.startTest();
        // Call the method with null additionalFields
        String returnMarker = Diab_SageInboundBatchHandler.processSageEmployeeRecords(new List<Diab_SageUtil.Diab_Sage_Employee>{testEmployee}, '2024-04-08');
        Test.stopTest();        
    }
    
     
    @isTest
    private static void isActiveEmployee_TEST() {
        Diab_SageUtil.Diab_Sage_Employee dummyEmployee = new Diab_SageUtil.Diab_Sage_Employee();
        List<Diab_SageUtil.Diab_Sage_AdditionalFields> additionalFields = new List<Diab_SageUtil.Diab_Sage_AdditionalFields>();
        // Add additional fields
        Diab_SageUtil.Diab_Sage_AdditionalFields additionalField = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        additionalField.name = 'Employment_Status';
        additionalField.value = 'Active';
        additionalFields.add(additionalField);
        dummyEmployee.additionalFields = additionalFields;
        
        Test.startTest();
        Boolean isActive = Diab_SageInboundBatchHandler.isActiveEmployee(dummyEmployee);
        Test.stopTest();
        
        // Assert the result
        System.assertEquals(true, isActive, 'Employee should be active');
    }

    @isTest
    private static void getValueFromAdditionalField_TEST(){
        Test.startTest();
        Diab_SageInboundBatchHandler.getValueFromAdditionalField(new List<Diab_SageUtil.Diab_Sage_AdditionalFields>{new Diab_SageUtil.Diab_Sage_AdditionalFields()},'a');
       // Diab_SageInboundBatchHandler.getValueFromAdditionalField(null,'');
        Test.stopTest();
    }

    @isTest
    private static void upsertPSAResources_TEST(){
        Test.startTest();

        Diab_SageInboundBatchHandler.upsertPSAResources(new List<Contact>{new Contact()},'');
        
        Test.stopTest();
    }

    @isTest
    private static void logManagerUpdateFailure_TEST(){
        Test.startTest();
        
        Contact ct = new Contact();
        ct.FirstName = 'Test Contact';
        Diab_SageInboundBatchHandler.logManagerUpdateFailure(Database.update(new List<Contact>{ct}, false), new List<Contact>{ct}, 'ReportsToId');
        
        Test.stopTest();
    }

    @isTest
    static void testGetContactRecordFromSageEmployee() {
        // Create test data
         Account testAccount = new Account(Name = 'Mobileum, Inc');
        insert testAccount;
        Diab_SageUtil.Diab_Sage_Employee sageEmployee = new Diab_SageUtil.Diab_Sage_Employee();
        sageEmployee.id = 'SAGE_EMPLOYEE_ID';
        sageEmployee.lastName = 'Doe';
       // sageEmployee.Diab_Sage_CurrentEmployment.jobTitle ='test';
        sageEmployee.firstName = 'John';
        sageEmployee.emailAddress = 'john.doe@example.com';
        Diab_SageUtil.Diab_Sage_AdditionalFields additionalField = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        additionalField.Name = 'Team_Member_Code';
        sageEmployee.additionalFields = new List<Diab_SageUtil.Diab_Sage_AdditionalFields>{additionalField};
       
        Diab_SageUtil.Diab_Sage_CurrentEmployment CuurentEmployeeField = new Diab_SageUtil.Diab_Sage_CurrentEmployment();
        CuurentEmployeeField.jobTitle ='test';
        sageEmployee.currentEmployment = CuurentEmployeeField;
        Map<String, Id> mapBusinessUnits = new Map<String, Id>{'BusinessUnit1' => testAccount.Id};
        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('PSA Resource').getRecordTypeId();




        // Call the method under test
        Contact contactRec = Diab_SageInboundBatchHandler.getContactRecordFromSageEmployee(sageEmployee, testAccount, mapBusinessUnits);

        // Verify the contact record values
		System.assertEquals(recordTypeId, contactRec.RecordTypeId);
        System.assertEquals('SAGE_EMPLOYEE_ID', contactRec.External_Id__c);
        System.assertEquals('Doe', contactRec.LastName);
        System.assertEquals('John', contactRec.FirstName);
        System.assertEquals('john.doe@example.com', contactRec.Email);
        System.assertEquals(testAccount.Id, contactRec.AccountId);
       // System.assertEquals('TM123', contactRec.Team_Member_Code__c);

    }
    

   @isTest
    private static void testgetValueFromAdditionalField(){
        Diab_SageUtil.Diab_Sage_AdditionalFields obj = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        obj.name = 'Test Name';
        obj.value = 'Test Value';
        obj.source = 'Test Source';
        System.assertEquals('Test Name', obj.name);
        System.assertEquals('Test Value', obj.value);
        System.assertEquals('Test Source', obj.source);
    }
}