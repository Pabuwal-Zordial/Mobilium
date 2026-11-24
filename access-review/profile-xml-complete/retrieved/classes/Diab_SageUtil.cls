public with sharing class Diab_SageUtil {
    public Diab_Integration_Settings__c integrationSettings;
    
    public Diab_SageUtil() {
        this.integrationSettings = Diab_Integration_Settings__c.getOrgDefaults();
    }

    public ResponseToken getAuthToken() {
        ResponseToken oauthToken = new ResponseToken();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setEndpoint(this.integrationSettings.Sage_Auth_Endpoint__c);

        req.setBody('grant_type=password' 
                    + '&client_id=' + this.integrationSettings.Sage_Client_Id__c 
                    + '&client_secret=' + this.integrationSettings.Sage_Client_Secret__c 
                    + '&username=' + this.integrationSettings.Sage_Username__c 
                    + '&password=' + this.integrationSettings.Sage_Password__c);

        Http http = new Http();
        HTTPResponse response = http.send(req);
        Integer statusCode = response.getStatusCode();
        string body = response.getBody();
        system.debug(response);
        System.debug('Body ' + response.getBody());
        System.debug('Status ' + response.getStatus());
        System.debug('Status code ' + response.getStatusCode());

        if (statusCode == 200) {
            oauthToken = (ResponseToken)JSON.deserialize(body, ResponseToken.class);
        } else {
            System.debug('Error occurred while retrieving Access Token.');
            System.debug('statusCode >> ' + statusCode);
            System.debug('body >> ' + body);
        }
        
        System.debug('oauthToken ' + oauthToken);

        return oauthToken;
    }

    public List<Diab_Sage_Employee> getEmployeeRecords(Boolean initialRun, ResponseToken token, string marker) {
        if (initialRun) {
            // Retrieve data using \employees?$filter endpoint without marker parameter.
            marker = '';
            token = this.getAuthToken();
        }

        // Retrieve data using \employees?$filter endpoint along with marker parameter (if not blank).
        List<Diab_Sage_Employee> sageEmployeesList = makeCallOut(token, marker);
        return sageEmployeesList;
    }

    public List<Diab_Sage_Employee> makeCallOut(ResponseToken token, String marker) {
        String teamFilterValue = this.integrationSettings.Sage_Team_Filter_Value__c;
        
        // MARKER
        String finalMarker = String.isBlank(marker) ? '' : 'marker='+ marker;

        // FILTER
        String yesterday = (string)DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).addDays(-1).format('yyyy-MM-dd');
        
        /**
         * Updating filter to support following scenario:
         * If an employee moves out of 'Global Delivery' department, he/she should be marked as Inactive in PSA and should not be available as a PSA Resource.
         */
        // String finalFilter = '$filter=Team_FF__c%20eq%20\'Global%20Delivery\'%20and%20(fHCM2__Current_Employment__r.Emp_Last_Modified_Date__c%20gt%20'+ yesterday +'%20or%20TM_Last_Modified_Date__c%20gt%20'+ yesterday +')';
        String finalFilter = '$filter=fHCM2__Current_Employment__r.Emp_Last_Modified_Date__c%20gt%20'+ yesterday +'%20or%20TM_Last_Modified_Date__c%20gt%20'+ yesterday + '%20' + 
                            'or%20fHCM2__Current_Employment__r.Emp_Last_Modified_Date__c%20eq%20'+ yesterday +'%20or%20TM_Last_Modified_Date__c%20eq%20'+ yesterday;
        
        /**
         * Reset filter if integrationSettings.Sage_Run_Full_Load__c is TRUE (i.e. Full Load)
         */
        if (this.integrationSettings.Sage_Run_Full_Load__c) {
            /**
             * Bringing in Sage Employees with Active employment status from ALL the departments.
             * During processing, it will filter out employees from departments that are listed in the new requirement.
             */
            //finalFilter = '$filter=Team_FF__c%20eq%20\''+ teamFilterValue.replace(' ', '%20') +'\'%20and%20fHCM2__Employment_Status__c%20eq%20\'Active\'';
            finalFilter = '$filter=fHCM2__Employment_Status__c%20eq%20\'Active\'';
        } 
        
        if (String.isNotBlank(finalMarker)) {
            finalFilter = '&' + finalFilter;
        }

        // Final Endpoint = Endpoint + Marker + Filter
        String finalEndpoint = this.integrationSettings.Sage_Employee_Endpoint__c;        
        if (String.isNotBlank(finalMarker) || String.isNotBlank(finalFilter)) {
            finalEndpoint = finalEndpoint + '?';
        }
        finalEndpoint = finalEndpoint + finalMarker + finalFilter;

        List<Diab_Sage_Employee> sageEmployeesList = new List<Diab_Sage_Employee>();

        System.debug('finalEndpoint ### ');
        System.debug(finalEndpoint);

        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setHeader('Accept','application/json');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Authorization', 'Bearer ' + token.access_token);
        req.setEndpoint(finalEndpoint);

        Http http = new Http();
        HTTPResponse response = http.send(req);
        Integer statusCode = response.getStatusCode();
        string body = response.getBody();

        if (statusCode == 200) {
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(body);
            
            sageEmployeesList = (List<Diab_Sage_Employee>)JSON.deserialize(JSON.serialize(jsonMap.get('data')), List<Diab_Sage_Employee>.class);
            System.debug('sageEmployeesList size >>> ' + sageEmployeesList?.size());
        } 
        else if (statusCode == 204) {
            // No Content
            // Done! - A blank list will be returned and the process will be completed.
            System.debug('204: No Content - Process has been completed successfully!!');
        } else if (statusCode == 401) {
            System.debug('401: Session Expired - Try again with new access_token!!');
        }
        else {
            System.debug('Error occurred in makeCallOut.');
            System.debug('statusCode >> ' + statusCode);
            System.debug('body >> ' + body);
        }

        return sageEmployeesList;
    }

    public class ResponseToken {
        public string access_token;
        public string instance_url;
        public string id;
        public string token_type;
        public string issued_at;
        public string signature;
    }
    
    public class Diab_Sage_Employee {
        public string id;
        public Diab_Sage_WorkAddress workAddress;
        public string lastName;
        public string hrDepartment;
        public string fullName;
        public string firstName;
        public string emailAddress;
        public Diab_Sage_CurrentEmployment currentEmployment;
        public List<Diab_Sage_AdditionalFields> additionalFields;
    }
    
    public class Diab_Sage_WorkAddress {
        public string region;
        public string postalCode;
        public string name;
        public string line3;
        public string line2;
        public string line1;
        public string country;
        public string city;
    }
    
    public class Diab_Sage_CurrentEmployment {
        public string startDate;
        public string name;
        public string jobTitle;
        public string endDate;
        public boolean active;
    }
    
    public class Diab_Sage_AdditionalFields {
        public string name;
        public string value;
        public string source;        
    }
}