@isTest(SeeAllData=true)
public  class Diab_SageUtilTest {
     
    public String jsonString = '{ "access_token": "00D000000000000!MOCK_ACCESS_TOKEN_FOR_TEST_ONLY", "instance_url": "https://mobileum-node--fullcopy.sandbox.my.salesforce.com", "id": "https://test.salesforce.com/id/00D7a0000005n6kEAA/005QJ000003nLyJYAU", "token_type": "Bearer", "issued_at": "1712226727367", "signature": "ZJNZ7cmkSD5uwYaPYr6eKqNGBwWcrTXO0065uba4HUI=" }';
    

    private class Diab_SageUtil_TEST implements HttpCalloutMock {
        protected Integer code;
        protected String status;
        protected String body;
        protected Map<String,String> headers;
        public Diab_SageUtil_TEST(Integer code,String status,String body,Map<String,String> headers) {
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
    public static void getAuthToken_TEST() {
        String jsonString = '{ "access_token": "00D000000000000!MOCK_ACCESS_TOKEN_FOR_TEST_ONLY", "instance_url": "https://mobileum-node--fullcopy.sandbox.my.salesforce.com", "id": "https://test.salesforce.com/id/00D7a0000005n6kEAA/005QJ000003nLyJYAU", "token_type": "Bearer", "issued_at": "1712226727367", "signature": "ZJNZ7cmkSD5uwYaPYr6eKqNGBwWcrTXO0065uba4HUI=" }';

        // Create mock integration settings
        Diab_Integration_Settings__c mockSettings = new Diab_Integration_Settings__c();
        Test.setMock(HttpCalloutMock.class, new Diab_SageUtil_TEST(200, 'Complete', Json.serialize(new Diab_SageUtil.ResponseToken()), null));

        Test.startTest();
        mockSettings= Diab_Integration();
        Diab_SageUtil obj = new Diab_SageUtil();
        obj.getAuthToken();
        
         obj.getEmployeeRecords(true, new Diab_SageUtil.ResponseToken(), 'a');

        Test.stopTest();
    }
    Private Static Diab_Integration_Settings__c Diab_Integration(){
        Diab_Integration_Settings__c mockSettings = [Select id ,name, Sage_Auth_Endpoint__c ,Sage_Employee_Endpoint__c ,Sage_Client_Id__c,
                                                     Sage_Client_Secret__c,Sage_Username__c ,Sage_Password__c,SetupOwnerId
                                                     from Diab_Integration_Settings__c limit 1];
            
        return mockSettings;
    }
}