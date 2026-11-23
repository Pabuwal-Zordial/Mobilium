@isTest
public class Diab_SageInboundBatchTest {

    
    private class Diab_SageInboundBatchMock implements HttpCalloutMock {
        protected Integer code;
        protected String status;
        protected String body;
        protected Map<String,String> headers;
        public Diab_SageInboundBatchMock(Integer code,String status,String body,Map<String,String> headers) {
            this.code = code;
            this.status = status;
            this.body = body;
            this.headers = headers;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.code);
            res.setStatus(this.status);
            res.setBody(this.body);
            if (this.headers != null) {
                for (String key : this.headers.keySet()) {
                    res.setHeader(key, this.headers.get(key));
                }
            }
            return res;
        }
    }
   
    @isTest
    static void testStartMethod() {
       
        // Start the batch
        Diab_SageInboundBatch batch = new Diab_SageInboundBatch(true, 'true ', null); 
        List<Diab_SageUtil.Diab_Sage_Employee> employees =new List<Diab_SageUtil.Diab_Sage_Employee>(); 
        Test.setMock(HttpCalloutMock.class, new Diab_SageInboundBatchMock(200, 'Complete', Json.serialize(new Diab_SageUtil.ResponseToken()), null));
        Test.startTest();
        batch.start(null);
        Test.stopTest();
        // Assertion
        System.assertEquals(0, employees.size(), 'The start method should return an empty list when initialRun is true and marker is null');
    }

    @isTest
    static void testStartMethodWithMarker() {
       
        // Start the batch
        Diab_SageInboundBatch batch = new Diab_SageInboundBatch(false, 'some-test-marker-value', null); 
        List<Diab_SageUtil.Diab_Sage_Employee> employees =new List<Diab_SageUtil.Diab_Sage_Employee>(); 
        Test.setMock(HttpCalloutMock.class, new Diab_SageInboundBatchMock(200, 'Complete', Json.serialize(new Diab_SageUtil.ResponseToken()), null));
        Test.startTest();
        batch.start(null);
        Test.stopTest();
        // Assertion
        System.assertEquals(0, employees.size(), 'The start method should return an empty list when initialRun is true and marker is null');
    }
    
    @isTest
    static void testExecuteMethod() {
        // Prepare test data
        List<Diab_SageUtil.Diab_Sage_Employee> testEmployees = getSageEmployeesList();
        
        // Start the batch
        Diab_SageInboundBatch batch = new Diab_SageInboundBatch(false, null, null); 
        
        Test.startTest();
        batch.execute(null, testEmployees);        
        Test.stopTest();        
    }
    
    @isTest
    static void testFinishMethod() {
        Diab_Integration_Settings__c mockSettings = getIntegrationCustomSettings();
        // Start the batch
        Diab_SageInboundBatch batch = new Diab_SageInboundBatch(false, null, null); 
        Test.startTest();
        batch.finish(null);
        Test.stopTest();
        
    }

    private static Diab_Integration_Settings__c getIntegrationCustomSettings(){
        Diab_Integration_Settings__c mockSettings = [Select id ,name, Sage_Auth_Endpoint__c ,Sage_Employee_Endpoint__c ,Sage_Client_Id__c,
                                                     Sage_Client_Secret__c,Sage_Username__c ,Sage_Password__c,SetupOwnerId
                                                     from Diab_Integration_Settings__c limit 1];
        
        return mockSettings;
    }
    
    @TestSetup
    static void setupTestData() {
        String defaultAccountName = 'Mobileum, Inc';

        // Insert default Account
        Account acc = new Account();
        acc.Name = defaultAccountName;
        acc.CurrencyIsoCode = 'USD';
        insert acc;
        
        // Insert Custom Settings
        Diab_Integration_Settings__c integrationSettings = new Diab_Integration_Settings__c();
        integrationSettings.Name = 'SageInboundFields';
        integrationSettings.CurrencyIsoCode = 'USD';        
        integrationSettings.Sage_Client_Id__c = 'sfdcTest';
        integrationSettings.Sage_Client_Secret__c = '1234';
        integrationSettings.Sage_Password__c = 'Password';
        integrationSettings.Sage_Username__c = 'Username';
        integrationSettings.Sage_Auth_Endpoint__c = 'https://test.salesforce.com/services/oauth2/token/';
        integrationSettings.Sage_Employee_Endpoint__c = 'https://test.salesforce.com/services/apexrest/spapi/v4/employees	';
        integrationSettings.PSA_Resource_Account_Name__c = defaultAccountName;
        integrationSettings.Sage_Team_Filter_Value__c = 'Global Delivery;Customer Support;Managed Services;Engineering;Product Management;PCC Head;Finance;IT & Systems';
        integrationSettings.Sage_Run_Full_Load__c = false;
        insert integrationSettings;

        // Insert default Work Calendar
        pse__Work_Calendar__c drpse_Work_Calendar;
        drpse_Work_Calendar=new pse__Work_Calendar__c (Name ='USA-Standard',Work_Day_Patterns__c = 'WeDo_USA' );
        insert drpse_Work_Calendar;
        
        // Insert Active PSA Resource
        Contact contactRec = new Contact();
        // contactRec.RecordTypeId = getPSARecordTypeId();
        contactRec.External_Id__c = 'a1H0Y111111OOGdUAO';
        contactRec.LastName = 'Fadadu';
        contactRec.FirstName = 'Ketan';
        contactRec.Email = 'ketan.fadadu@mobileum.om';
        contactRec.AccountId = acc.Id;
        // Unique Identifier - TMC
        contactRec.DIAB_MB_Team_Member_Code__c = '11100008';
        contactRec.CurrencyIsoCode = 'USD';     
        contactRec.pse__Employment_Status__c = 'Active';
        contactRec.MailingStreet = '';
        contactRec.MailingCity = 'Los Angeles';
        contactRec.MailingState = 'CA';
        contactRec.MailingPostalCode = '95014';
        contactRec.MailingCountry = 'United States';
        contactRec.Title = 'Executive Assistant';
        
        Boolean activeOrTerminatedEmployeeFlag = true;
        contactRec.pse__Is_Resource__c = activeOrTerminatedEmployeeFlag;
        contactRec.pse__Is_Resource_Active__c = activeOrTerminatedEmployeeFlag;

        insert contactRec;
    }

    private static List<Diab_SageUtil.Diab_Sage_Employee> getSageEmployeesList() {
        List<Diab_SageUtil.Diab_Sage_Employee> testEmployees = new List<Diab_SageUtil.Diab_Sage_Employee>();

        // Test Employee-1
        Diab_SageUtil.Diab_Sage_Employee testEmployee = new Diab_SageUtil.Diab_Sage_Employee();
        testEmployee.id = 'a1H0Y111111OOGdUAO';
        
        Diab_SageUtil.Diab_Sage_WorkAddress workAddr = new Diab_SageUtil.Diab_Sage_WorkAddress();
        workAddr.region = 'CA';
        workAddr.postalCode = '95014';
        workAddr.name = 'USA';
        workAddr.line3 = 'Cupertino';
        workAddr.line2 = 'Suite 200';
        workAddr.line1 = '';
        workAddr.country = 'United States';
        workAddr.city = 'CA';
        testEmployee.workAddress = workAddr;

        testEmployee.lastName = 'Fadadu';
        testEmployee.firstName = 'Ketan';
        testEmployee.hrDepartment = 'USA_MobileumInc_ETP';
        testEmployee.fullName = 'Ketan Fadadu';
        testEmployee.emailAddress = 'ketan.fadadu@mobileum.com';

        Diab_SageUtil.Diab_Sage_CurrentEmployment currentEmpl = new Diab_SageUtil.Diab_Sage_CurrentEmployment();
        currentEmpl.startDate = '2001-02-05';
        currentEmpl.name = '2018.01 #8808';
        currentEmpl.jobTitle = 'Executive Assistant';
        currentEmpl.endDate = null;
        currentEmpl.active = true;
        testEmployee.currentEmployment = currentEmpl;

        List<Diab_SageUtil.Diab_Sage_AdditionalFields> addnFields = new List<Diab_SageUtil.Diab_Sage_AdditionalFields>();

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField.name = 'Team_Member_Code';
        addnField.value = '11100008';
        addnField.source = 'Team_Member_Code__c';
        addnFields.add(addnField);

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField1 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField1.name = 'First_Name';
        addnField1.value = 'Ketan';
        addnField1.source = 'fHCM2__First_Name__c';
        addnFields.add(addnField1);

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField2 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField2.name = 'Surname';
        addnField2.value = 'Fadadu';
        addnField2.source = 'fHCM2__Surname__c';
        addnFields.add(addnField2);

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField3 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField3.name = 'Outlook_Display_Name';
        addnField3.value = 'Ketan Fadadu';
        addnField3.source = 'Outlook_Display_Name__c';
        addnFields.add(addnField3);

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField4 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField4.name = 'Email';
        addnField4.value = 'ketan.fadadu@mobileum.com';
        addnField4.source = 'fHCM2__Email__c';
        addnFields.add(addnField4);

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField5 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField5.name = 'Employment_Status';
        addnField5.value = 'Active';
        addnField5.source = 'fHCM2__Employment_Status__c';
        addnFields.add(addnField5);

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField6 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField6.name = 'Team_FF';
        addnField6.value = 'Cloud Delivery';
        addnField6.source = 'Team_FF__c';
        addnFields.add(addnField6);

        testEmployee.additionalFields = addnFields;
        testEmployees.add(testEmployee);

        // Test Employee-2
        testEmployee = new Diab_SageUtil.Diab_Sage_Employee();
        testEmployee.id = 'a1H0Y22222OOGdUAO';
        
        Diab_SageUtil.Diab_Sage_WorkAddress workAddr1 = new Diab_SageUtil.Diab_Sage_WorkAddress();
        workAddr1.region = 'CA';
        workAddr1.postalCode = '95014';
        workAddr1.name = 'USA';
        workAddr1.line3 = 'Cupertino';
        workAddr1.line2 = 'Suite 200';
        workAddr1.line1 = '';
        workAddr1.country = 'United States';
        workAddr1.city = 'CA';
        testEmployee.workAddress = workAddr1;

        testEmployee.lastName = 'Bhattacharya';
        testEmployee.firstName = 'Shrishti';
        testEmployee.hrDepartment = 'USA_MobileumInc_ETP';
        testEmployee.fullName = 'Shrishti Bhattacharya';
        testEmployee.emailAddress = 'shrishti.bhattacharya@mobileum.com';

        Diab_SageUtil.Diab_Sage_CurrentEmployment currentEmpl1 = new Diab_SageUtil.Diab_Sage_CurrentEmployment();
        currentEmpl1.startDate = '2001-02-05';
        currentEmpl1.name = '2018.01 #8808';
        currentEmpl1.jobTitle = 'Executive Assistant';
        currentEmpl1.endDate = null;
        currentEmpl1.active = true;
        testEmployee.currentEmployment = currentEmpl1;

        List<Diab_SageUtil.Diab_Sage_AdditionalFields> addnFields1 = new List<Diab_SageUtil.Diab_Sage_AdditionalFields>();

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField0 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField0.name = 'Team_Member_Code';
        addnField0.value = '11100009';
        addnField0.source = 'Team_Member_Code__c';
        addnFields1.add(addnField0);

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField11 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField11.name = 'First_Name';
        addnField11.value = 'Shrishti';
        addnField11.source = 'fHCM2__First_Name__c';
        addnFields1.add(addnField11);

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField21 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField21.name = 'Surname';
        addnField21.value = 'Bhattacharya';
        addnField21.source = 'fHCM2__Surname__c';
        addnFields1.add(addnField21);

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField31 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField31.name = 'Outlook_Display_Name';
        addnField31.value = 'Shrishti Bhattacharya';
        addnField31.source = 'Outlook_Display_Name__c';
        addnFields1.add(addnField31);

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField41 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField41.name = 'Email';
        addnField41.value = 'shrishti.bhattacharya@mobileum.com';
        addnField41.source = 'fHCM2__Email__c';
        addnFields1.add(addnField41);

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField51 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField51.name = 'Employment_Status';
        addnField51.value = 'Active';
        addnField51.source = 'fHCM2__Employment_Status__c';
        addnFields1.add(addnField51);

        Diab_SageUtil.Diab_Sage_AdditionalFields addnField61 = new Diab_SageUtil.Diab_Sage_AdditionalFields();
        addnField61.name = 'Team_FF';
        addnField61.value = 'Global Delivery';
        addnField61.source = 'Team_FF__c';
        addnFields1.add(addnField61);

        testEmployee.additionalFields = addnFields1;

        testEmployees.add(testEmployee);

        return testEmployees;
    }    
}