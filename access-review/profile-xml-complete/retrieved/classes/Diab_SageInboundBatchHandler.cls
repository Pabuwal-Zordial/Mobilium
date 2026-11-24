public with sharing class Diab_SageInboundBatchHandler {
    public static Diab_Integration_Settings__c integrationSettings = Diab_Integration_Settings__c.getOrgDefaults();
    public static List<String> departmentsList = integrationSettings.Sage_Team_Filter_Value__c?.split(';');
    public static Map<String, Id> mapWorkCalendarPatterns = new Map<String, Id>();
    //public static pse__Work_Calendar__c defaultWorkCalendar;
    public static Map<String, Id> mapExistingActivePSAResources = new Map<String, Id>();
    public static Map<String, String> mapJobTitleVsResourceRole = new Map<String, String>();

    public Diab_SageInboundBatchHandler() {}

    public static String processSageEmployeeRecords(List<Diab_SageUtil.Diab_Sage_Employee> sageEmployeesList, String batchDateTime) {
        Map<String, Id> mapBusinessUnits = getBusinessUnitsMap();
        mapWorkCalendarPatterns = getWorkCalendarPatternsMap();
        mapExistingActivePSAResources = getExistingActivePSAResourcesMap();
        mapJobTitleVsResourceRole = getJobTitleResourceRoleMap();
        
        //defaultWorkCalendar = [SELECT Id, Name, Work_Day_Patterns__c FROM pse__Work_Calendar__c WHERE Name = 'USA-Standard' LIMIT 1];
        String returnMarker = '';

        if (sageEmployeesList == null || sageEmployeesList?.size() == 0) {
            return returnMarker;
        }
        
        Account account = getAccountRecord();

        List<Contact> sageEmployeesListToUpsert = new List<Contact>();
        for (Diab_SageUtil.Diab_Sage_Employee sageEmployee : sageEmployeesList) {
            if (isEmployeeInListedDepartment(sageEmployee)) {
                Contact psaResource = getContactRecordFromSageEmployee(sageEmployee, account, mapBusinessUnits);
                sageEmployeesListToUpsert.add(psaResource);
            } else if (wasEmployeeActivePSAResourcePreviously(sageEmployee)) {
                // This employee has moved out from Global Delivery to some other department hence marking as Inactive in PSA.
                // System.debug('Employee was an Active PSAResource previously ### ===> ' + sageEmployee.additionalFields);
                // System.debug('Employee was an Active PSAResource previously. Current Team_FF is ### ===> ' + getValueFromAdditionalField(sageEmployee.additionalFields, 'Team_FF'));
                Contact psaResource = getContactRecordFromSageEmployee(sageEmployee, account, mapBusinessUnits);
                psaResource.pse__Is_Resource__c = false;
                psaResource.pse__Is_Resource_Active__c = false;
                sageEmployeesListToUpsert.add(psaResource);
            }
        }

        if (sageEmployeesListToUpsert?.size() > 0) {
            upsertPSAResources(sageEmployeesListToUpsert, batchDateTime);
            returnMarker = sageEmployeesListToUpsert[sageEmployeesListToUpsert.size()-1].External_Id__c;
        }

        return returnMarker;
    }

    private static Boolean isEmployeeInListedDepartment(Diab_SageUtil.Diab_Sage_Employee sageEmployee){
        Boolean returnVal = false;
        String teamFF = getValueFromAdditionalField(sageEmployee.additionalFields, 'Team_FF');
        returnVal = isTeamInListedDepartments(teamFF);
        
        // System.debug('isEmployeeInListedDepartment -> teamFF ### ==> ' + teamFF);
        // System.debug('isEmployeeInListedDepartment -> ### ==> ' + returnVal);

        return returnVal;
    }

    private static Boolean wasEmployeeActivePSAResourcePreviously(Diab_SageUtil.Diab_Sage_Employee sageEmployee){
        Boolean returnVal = false;
        String currentTeamFF = getValueFromAdditionalField(sageEmployee.additionalFields, 'Team_FF');
        String currentTeamMemberCode = getValueFromAdditionalField(sageEmployee.additionalFields, 'Team_Member_Code');

        if (currentTeamFF == null || !isTeamInListedDepartments(currentTeamFF)) {
            returnVal = (mapExistingActivePSAResources.containsKey(currentTeamMemberCode) && mapExistingActivePSAResources.get(currentTeamMemberCode) != null);
            // System.debug('wasEmployeeInListedDepartmentPreviously ### ---> ' + returnVal);
        }

        return returnVal;
    }

    private static Boolean isTeamInListedDepartments(String teamFF){
        Boolean returnVal = false;
        
        // System.debug('isTeamInListedDepartments -> teamFF ### ==> ' + teamFF);

        if (teamFF != null && departmentsList != null && departmentsList.size() > 0) {
            for (String dept : departmentsList) {
                if (teamFF.equals(dept)) {
                    returnVal = true;
                    break;
                }
            }
        }

        return returnVal;
    }

    public static Contact getContactRecordFromSageEmployee(Diab_SageUtil.Diab_Sage_Employee sageEmployee, Account account, Map<String, Id> mapBusinessUnits) {
        Contact contactRec = new Contact();
        contactRec.RecordTypeId = getPSARecordTypeId();
        contactRec.External_Id__c = sageEmployee.id;
        contactRec.LastName = sageEmployee.lastName;
        contactRec.FirstName = sageEmployee.firstName;
        contactRec.Email = sageEmployee.emailAddress;
        //contactRec.Account = account;
        contactRec.AccountId = account.Id;
        // Unique Identifier - TMC
        contactRec.DIAB_MB_Team_Member_Code__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Team_Member_Code');
        contactRec.CurrencyIsoCode = getValueFromAdditionalField(sageEmployee.additionalFields, 'Salary_Currency');
        // contactRec.pse__Resource_Role__c = sageEmployee.currentEmployment.jobTitle;
        //contactRec.pse__Resource_Role__c = mapJobTitleVsResourceRole?.get(sageEmployee.currentEmployment.jobTitle);
        //contactRec.pse__Work_Calendar__c = getWorkCalender(getValueFromAdditionalField(sageEmployee.additionalFields, 'Work_Day_Pattern_FF'));
       
       /**-----added by sunita-------**/
       
            String tmc = getValueFromAdditionalField(sageEmployee.additionalFields, 'Team_Member_Code');
             system.debug('tmc ###'+tmc);
           
            
             Contact existing;
            List<Contact> results = [
                SELECT Id, pse__Work_Calendar__c
                FROM Contact
                WHERE DIAB_MB_Team_Member_Code__c = :tmc
                LIMIT 1
            ];
            if (!results.isEmpty()) {
                existing = results[0];
            }
            system.debug('existing ###'+existing);

            String workPattern = getValueFromAdditionalField(sageEmployee.additionalFields, 'Work_Day_Pattern_FF');

            if (String.isBlank(workPattern) && existing != null) {
                //contactRec.pse__Work_Calendar__c = existing != null ? existing.pse__Work_Calendar__c : null;
                system.debug('existing ###'+existing);
                contactRec.pse__Work_Calendar__c = existing.pse__Work_Calendar__c;
                system.debug('existing.pse__Work_Calendar__c###'+existing.pse__Work_Calendar__c);
            }
            else if (String.isBlank(workPattern) && existing == null) {
                contactRec.pse__Work_Calendar__c = null;
                system.debug('enter else if###'+contactRec.pse__Work_Calendar__c);
            }else {
                contactRec.pse__Work_Calendar__c = getWorkCalender(workPattern);
                system.debug('enter else only###'+contactRec.pse__Work_Calendar__c);
            }
 /**-----added by sunita end-------**/
        contactRec.pse__Start_Date__c = String.isBlank(sageEmployee.currentEmployment.startDate) ? null : Date.valueOf(sageEmployee.currentEmployment.startDate);
        contactRec.pse__Last_Date__c = String.isBlank(sageEmployee.currentEmployment.endDate) ? null : Date.valueOf(sageEmployee.currentEmployment.endDate);        
        contactRec.pse__Employment_Status__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Employment_Status');
        contactRec.DIAB_MB_Employment_Sub_Status__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Sub_Status');
        contactRec.DIAB_MB_Employment_Type__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Agreement_Type');
        /**
         * Set External Resource flag to TRUE if Agreement_Type != 'Employee'
         */
        contactRec.pse__External_Resource__c = (contactRec.DIAB_MB_Employment_Type__c != 'Employee' && contactRec.DIAB_MB_Employment_Type__c != 'EOR Employee') ? true : false;
        /**
         * Changing the field name from 'Business_FF' to 'BU' as per Pankaj Gupta's request for PROD environment.
         */
        // contactRec.pse__Practice__c = mapBusinessUnits.get(getValueFromAdditionalField(sageEmployee.additionalFields, 'Business_FF'));
        contactRec.pse__Practice__c = mapBusinessUnits.get(getValueFromAdditionalField(sageEmployee.additionalFields, 'BU'));
        
        /**
         * Department field should be populated with Sage->Team_FF field instead of Department_Bucket. 
         * Department_Bucket field is NO longer required to store in Certinia (confirmed by Mobileum team via email).
         */
        // contactRec.Department__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Department_Bucket');
        contactRec.Department__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Team_FF');
        contactRec.DIAB_MB_Sub_Department__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Sub_Department_FF');
        contactRec.DIAB_MB_Finance_Cost_Centre_Name__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Finance_Cost_Center_Name');
        contactRec.DIAB_MB_Finance_Cost_Centre_Code__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Finance_Code');
        /**
         * Changing the field name from 'Office_Location' to 'Location_ff' as per Pankaj Gupta's request for PROD environment.
         */
        // contactRec.DIAB_MB_Resource_Location__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Office_Location');
        contactRec.DIAB_MB_Resource_Location__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Location_ff');
        /**
         * Added a new field for Sage Team since we now have employees from multiple teams from Sage.
         */
        
        /**
         * Below field NO longer required. Instead, we are using Department__c field to store Sage's Team_FF field.
         */
        //contactRec.DIAB_MB_Sage_Team__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Team_FF');
        if (sageEmployee.workAddress != null) {
            contactRec.MailingStreet = sageEmployee.workAddress.line1;
            contactRec.MailingCity = sageEmployee.workAddress.city;
            contactRec.MailingState = sageEmployee.workAddress.region;
            contactRec.MailingPostalCode = sageEmployee.workAddress.postalCode;
            contactRec.MailingCountry = sageEmployee.workAddress.country;
        }
        if (sageEmployee.currentEmployment != null) {
            contactRec.Title = sageEmployee.currentEmployment.jobTitle;
        }
        contactRec.DIAB_MB_Manager_Team_Member_Code__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Manager_Team_Member_Code_FF');
        contactRec.DIAB_MB_Resource_Pool__c = getValueFromAdditionalField(sageEmployee.additionalFields, 'Sub_Department_FF');
        contactRec.Working_Hours__c = getResourceWorkingHours(sageEmployee);
        Boolean activeOrTerminatedEmployeeFlag = isActiveEmployee(sageEmployee);
        contactRec.pse__Is_Resource__c = activeOrTerminatedEmployeeFlag;
        contactRec.pse__Is_Resource_Active__c = activeOrTerminatedEmployeeFlag;

        return contactRec;
    }

    public static Boolean isActiveEmployee(Diab_SageUtil.Diab_Sage_Employee employee) {
        String employmentStatus = getValueFromAdditionalField(employee.additionalFields, 'Employment_Status');
        if (employmentStatus == 'Active') {
            return true;
        }
        return false;
    }

    public static String getValueFromAdditionalField(List<Diab_SageUtil.Diab_Sage_AdditionalFields> additionalFields, String fieldName) {
        String retVal = '';
        for (Diab_SageUtil.Diab_Sage_AdditionalFields addnFld : additionalFields) {
            if (addnFld.name == fieldName) {
                retVal = addnFld.value?.replace('&amp;', '&');
            }
        }
        return retVal;
    }   

    private static Account getAccountRecord() {
        String defaultAccountName = integrationSettings.PSA_Resource_Account_Name__c;
        Account mobAccount = [Select Id, Name From Account Where Name =:defaultAccountName limit 1];
        return mobAccount;
    } 

    private static Map<String,Id> getBusinessUnitsMap(){
        List<pse__Practice__c> businessUnitsList = [SELECT Name, Id FROM pse__Practice__c];
        Map<String, Id> mapBUs = new Map<String, Id>();

        for(pse__Practice__c bu :businessUnitsList) {
            mapBUs.put(bu.Name, bu.Id);
        }

        return mapBUs;
    } 

    private static Id getWorkCalender(String work_Day_Pattern_FF){
        // DEFAULT CALENDAR ==> NULL (if required, replace null with defaultWorkCalendar which is currently set to USA-Standard calendar.)
        
         
        return mapWorkCalendarPatterns.containsKey(work_Day_Pattern_FF) ? mapWorkCalendarPatterns.get(work_Day_Pattern_FF) : null;
        
    } 

    private static String getPSARecordTypeId(){
        return Schema.SObjectType.Contact.getRecordTypeInfosByName().get('PSA Resource').getRecordTypeId();
    } 

    private static Map<String,Id> getWorkCalendarPatternsMap(){
        Map<String, Id> mapWorkCalendarPatterns = new Map<String, Id>();        
        List<pse__Work_Calendar__c> workCalendarList = [SELECT Id, Name, Work_Day_Patterns__c FROM pse__Work_Calendar__c WHERE Work_Day_Patterns__c != null];
        List<String> workPatternsList = new List<String>();

        for (pse__Work_Calendar__c wc :workCalendarList) {
            workPatternsList = wc.Work_Day_Patterns__c?.split(';');
            for (String pattern : workPatternsList) {
                mapWorkCalendarPatterns.put(pattern, wc.Id);
            }
        }

        return mapWorkCalendarPatterns;
    } 

    private static Map<String,Id> getExistingActivePSAResourcesMap() {
        Map<String, Id> mapActivePSAResources = new Map<String, Id>();

        for (Contact c : [SELECT Id, DIAB_MB_Team_Member_Code__c 
                          FROM Contact 
                          WHERE DIAB_MB_Team_Member_Code__c != null 
                            AND pse__Is_Resource__c = true 
                            AND pse__Is_Resource_Active__c = true]) {
            mapActivePSAResources.put(c.DIAB_MB_Team_Member_Code__c, c.Id);
        }

        return mapActivePSAResources;
    }

    private static Map<String,String> getJobTitleResourceRoleMap(){
        Map<String, String> mapResourceRoles = new Map<String, String>();
        List<DIAB_MB_Resource_Role_Mappings__mdt> mappings = [SELECT DIAB_MB_Job_Title__c, DIAB_MB_Resource_Role__c 
                                                                FROM DIAB_MB_Resource_Role_Mappings__mdt];

        for (DIAB_MB_Resource_Role_Mappings__mdt mapping : mappings) {
            mapResourceRoles.put(mapping.DIAB_MB_Job_Title__c, mapping.DIAB_MB_Resource_Role__c);
        }

        return mapResourceRoles;
    } 

    private static Map<String,Id> getTMCVsSFUserMap(){
        Map<String, Id> tmcVsSFUserMap = new Map<String, Id>();
        List<Contact> contacts = [SELECT Id, DIAB_MB_Team_Member_Code__c, pse__Salesforce_User__c 
                                    FROM Contact 
                                    WHERE DIAB_MB_Team_Member_Code__c != null 
                                        AND (NOT(DIAB_MB_Team_Member_Code__c LIKE 'MISS%')) 
                                        AND pse__Salesforce_User__c != null];

        for (Contact ct : contacts) {
            tmcVsSFUserMap.put(ct.DIAB_MB_Team_Member_Code__c, ct.pse__Salesforce_User__c);
        }

        return tmcVsSFUserMap;
    } 

    private static Map<String,Id> getTMCVsContactIdMap(){
        Map<String, Id> tmcVsContactIdMap = new Map<String, Id>();
        List<Contact> contacts = [SELECT Id, DIAB_MB_Team_Member_Code__c 
                                    FROM Contact 
                                    WHERE DIAB_MB_Team_Member_Code__c != null 
                                        AND (NOT(DIAB_MB_Team_Member_Code__c LIKE 'MISS%'))];

        for (Contact ct : contacts) {
            tmcVsContactIdMap.put(ct.DIAB_MB_Team_Member_Code__c, ct.Id);
        }

        return tmcVsContactIdMap;
    }

    private static Decimal getResourceWorkingHours(Diab_SageUtil.Diab_Sage_Employee employee) {
        String workingHours = getValueFromAdditionalField(employee.additionalFields, 'Working_Hours_FF');
        Decimal returnValue;
        if (String.isBlank(workingHours) || Decimal.valueOf(workingHours) <= 0) {
            returnValue = integrationSettings.Default_Working_Hours__c;
        } else {
            returnValue = Decimal.valueOf(workingHours);
        }
        return returnValue;
    }

    public static void upsertPSAResources(List<Contact> sageEmployeesListToUpsert, String batchDateTime) {
        System.debug('INSIDE upsertPSAResources -> sageEmployeesListToUpsert ### size --> ' + sageEmployeesListToUpsert?.size());

       // Schema.SObjectField externalId = Contact.Fields.External_Id__c;
       
        Schema.SObjectField teamMemberCodeField = Contact.DIAB_MB_Team_Member_Code__c;
        Database.UpsertResult[] upsResult = Database.upsert(sageEmployeesListToUpsert, teamMemberCodeField, false);
        //Database.UpsertResult[] upsResult = Database.upsert(sageEmployeesListToUpsert, Contact.External_Id__c, false);


        
        List<Contact> contactsToUpdateReportsToAndManagerList = populateIDsFromUpsertResult(sageEmployeesListToUpsert, upsResult);

        // Update Contact -> ReportsTo && User -> Manager fields for the saved records.
        updateContactReportsToAndUserManagerFields(contactsToUpdateReportsToAndManagerList);

        // Process all records - success & failure
        prepareIntegrationLog(sageEmployeesListToUpsert, upsResult, batchDateTime);        
    } 

    private static List<Contact> populateIDsFromUpsertResult(List<Contact> sageEmployeesListToUpsert, List<Database.UpsertResult> upsResults){
        List<Contact> successfullyCreatedUpdatedContactsList = new List<Contact>();

        // Iterate through the results and update the original list
        for (Integer i = 0; i < upsResults.size(); i++) {
            if (upsResults[i].isSuccess()) {
                Contact successContact = new Contact();
                // Update the original list with the new ID for created/updated records
                successContact = sageEmployeesListToUpsert[i];
                successContact.Id = upsResults[i].getId();
                successfullyCreatedUpdatedContactsList.add(successContact);
            }
        }

        return successfullyCreatedUpdatedContactsList;
    } 

    private static void updateContactReportsToAndUserManagerFields(List<Contact> sageEmployeesListToUpsert) {
        // Contact --> ReportsTo
        Map<String, Id> mapTMCVsSFUser = getTMCVsSFUserMap();
        Map<String, Id> mapTMCVsContactId = getTMCVsContactIdMap();
        List<Contact> contactsToUpdateReportsToList = new List<Contact>();

        // User --> ManagerId
        Map<Id, String> mapSalesforceUserIDVsManagerTMC = new Map<Id, String>();

        for (Contact ct : sageEmployeesListToUpsert) {
            // Contact --> ReportsTo
            if (ct?.DIAB_MB_Manager_Team_Member_Code__c != null && mapTMCVsContactId.containsKey(ct.DIAB_MB_Manager_Team_Member_Code__c)) {
                Contact ctUpdateReportsTo = new Contact();
                ctUpdateReportsTo.Id = ct.Id;
                ctUpdateReportsTo.ReportsToId = mapTMCVsContactId?.get(ct.DIAB_MB_Manager_Team_Member_Code__c);
                //ct.ReportsToId = mapTMCVsContactId?.get(ct.DIAB_MB_Manager_Team_Member_Code__c);
                contactsToUpdateReportsToList.add(ctUpdateReportsTo);
                // System.debug('contactsToUpdateReportsToList - ctUpdateReportsTo ### ' + ctUpdateReportsTo);
            }

            // User --> ManagerId
            if (mapTMCVsSFUser.containsKey(ct.DIAB_MB_Team_Member_Code__c) && ct?.DIAB_MB_Manager_Team_Member_Code__c != null) {
                mapSalesforceUserIDVsManagerTMC.put(mapTMCVsSFUser.get(ct.DIAB_MB_Team_Member_Code__c), ct.DIAB_MB_Manager_Team_Member_Code__c);                
            }
        }

        // User --> ManagerId
        System.debug('mapSalesforceUserIDVsManagerTMC size ### ' + mapSalesforceUserIDVsManagerTMC.size());
        System.debug(mapSalesforceUserIDVsManagerTMC);

        List<User> sfUsersList = [SELECT Id, ManagerId FROM User WHERE Id in :mapSalesforceUserIDVsManagerTMC.keySet()];
        
        System.debug('sfUsersList size ### ' + sfUsersList.size());
        System.debug(sfUsersList);

        List<User> usersToUpdateManagerIdList = new List<User>();
        String currentManagerTMC = '';
        for (User u : sfUsersList) {
            currentManagerTMC = mapSalesforceUserIDVsManagerTMC.get(u.Id);
            
            if (String.isNotBlank(currentManagerTMC) && mapTMCVsSFUser.containsKey(currentManagerTMC)) {
                u.ManagerId = mapTMCVsSFUser.get(currentManagerTMC);
                usersToUpdateManagerIdList.add(u);
                // System.debug('usersToUpdateManagerIdList - u ### ' + u);
            }
        }

        try {
            System.debug('contactsToUpdateReportsToList size ### ' + contactsToUpdateReportsToList.size());
            System.debug(contactsToUpdateReportsToList);
            //update contactsToUpdateReportsToList;
            Database.SaveResult[] dbSaveResultsContact = Database.update(contactsToUpdateReportsToList, false);

            // Log errors
            logManagerUpdateFailure(dbSaveResultsContact, contactsToUpdateReportsToList, 'ReportsToId');
        } catch (Exception ex) {
            System.debug('### Error occurred while updating ReportsTo field : ' + ex.getMessage());
            System.debug('### StackTrace : ' + ex.getStackTraceString());
        }

        try {
            // update usersToUpdateManagerIdList;
            Database.SaveResult[] dbSaveResultsUsers = Database.update(usersToUpdateManagerIdList, false);

            // Log errors
            logManagerUpdateFailure(dbSaveResultsUsers, usersToUpdateManagerIdList, 'ManagerId');
        } catch (Exception ex) {
            System.debug('### Error occurred while updating User-Manager field : ' + ex.getMessage());
            System.debug('### StackTrace : ' + ex.getStackTraceString());
        }
    }

    @TestVisible
    private static void logManagerUpdateFailure(List<Database.SaveResult> dbSaveResults, List<SObject> sObjList, String fieldName) {

        if (sObjList == null || sObjList.isEmpty()) {
            return;
        }

        List<Diab_Integration_Log__c> logRecords = new List<Diab_Integration_Log__c>();
        if (dbSaveResults != null && dbSaveResults.size() > 0) {
            for (Integer i = 0; i < dbSaveResults.size(); i++) {
                if (!dbSaveResults[i].isSuccess()) {
                    String errorMessage = '';
                    String errorStatusCode = '';

                    for (Database.Error err : dbSaveResults[i].getErrors()) {
                        // Capture only first error.
                        errorStatusCode = err.getStatusCode()?.toString();
                        errorMessage = err.getMessage();
                        break;
                    }

                    SObject failedRecord = sObjList[i];
                    Diab_Integration_Log__c logRec = new Diab_Integration_Log__c();
                    logRec.Integration_System__c = 'Sage';
                    logRec.Integration_Type__c = 'Inbound';
                    if (fieldName == 'ReportsToId') {
                        logRec.Contact__c = (String) failedRecord.get('Id');
                    }                    
                    logRec.Integration_Action__c = 'Update';
                    logRec.Integration_Status__c = 'Error';
                    logRec.Error_Status_Code__c = errorStatusCode;
                    errorMessage = (errorMessage != null && errorMessage.length() > 255) ? errorMessage?.substring(0, 254) : errorMessage;
                    logRec.Error_Message__c = errorMessage;
                    logRec.Error_Fields__c = '(' + fieldName + ')';
                    String recordJson = JSON.serialize(sObjList[i]);
                    recordJson = (recordJson != null && recordJson.length() > 131070) ? recordJson?.substring(0, 131070) : recordJson;
                    logRec.Record_JSON__c = recordJson;

                    logRecords.add(logRec);
                }
            }
        }            

        if (!logRecords.isEmpty()) {
            Database.SaveResult[] dbSaveResultsIntLog = Database.insert(logRecords, false);
        }
    }

    private static void prepareIntegrationLog(List<Contact> sageEmployeesListToUpsert, Database.UpsertResult[] upsResults, String batchDateTime) {
        //Map<Id, Contact> sageEmployeesMap = new Map<Id, Contact>(sageEmployeesListToUpsert);
        List<Diab_Integration_Log__c> integrationLogList = new List<Diab_Integration_Log__c>();
        List<Diab_Exception_Log__c> exceptionLogList = new List<Diab_Exception_Log__c>();
        Diab_Integration_Log__c intLog;
        Diab_Exception_Log__c excLog;
        // String batchDateTime = System.DateTime.now().toString();
        Integer index = 0;
        Boolean failedRecordLogged = false;

        for(Database.UpsertResult result : upsResults) {
            // System.debug(result);

            String intAction = '';
            if(result.isSuccess()){
                // INSERT INTO INTEGRATION LOG
                if(result.isCreated()){
                    //System.debug(sageEmployeesMap.get(result.getId()).Id + ' was created');
                    //System.debug(sageEmployeesListToUpsert[index].Id + ' was created');
                    intAction = 'Create';
                } else {
                    //System.debug(sageEmployeesMap.get(result.getId()).Id + ' was updated');
                    //System.debug(sageEmployeesListToUpsert[index].Id + ' was updated');
                    if (!sageEmployeesListToUpsert[index].pse__Is_Resource__c && !sageEmployeesListToUpsert[index].pse__Is_Resource_Active__c) {
                        intAction = 'Inactive';
                    } else {
                        intAction = 'Update';
                    }
                    
                }
                intLog = prepareIntLogRecord(batchDateTime, 
                                            sageEmployeesListToUpsert[index],
                                            intAction, 
                                            'Success',
                                            null,
                                            null,
                                            null);                
            } else {
                // INSERT INTO EXCEPTION LOG
                failedRecordLogged = false;
                for(Database.Error err : result.getErrors()) {
                    
                    // System.debug('ERROR: ' + err.getStatusCode() + ': ' + err.getMessage());
                    // System.debug('Fields in error: ' + err.getFields());
                    // System.debug('Record Id: ' + result.getId());
                    
                    excLog = createExceptionLogRecord(result.getId(), err.getStatusCode()?.toString(), err.getMessage(), err.getFields());
                    exceptionLogList.add(excLog);

                    // Log first error in Integration Log Record.
                    if (!failedRecordLogged) {
                        intLog = prepareIntLogRecord(batchDateTime, 
                                                    sageEmployeesListToUpsert[index],
                                                    'N/A', 
                                                    'Error',
                                                    err.getStatusCode()?.toString(),
                                                    err.getMessage(),
                                                    err.getFields()?.toString());
                        failedRecordLogged = true;                        
                    }
                }
            }
            integrationLogList.add(intLog);
            index++;
        }
        if (integrationLogList?.size() > 0) {
            // System.debug('integrationLogList ### Size -> ' + integrationLogList.size());
            // System.debug(integrationLogList);
            insert integrationLogList;
        }
        if (exceptionLogList?.size() > 0) {
            // System.debug('exceptionLogList ### Size -> ' + exceptionLogList.size());
            // System.debug(exceptionLogList);
            insert exceptionLogList;
        }
    }

    private static Diab_Integration_Log__c prepareIntLogRecord(String batchDateTime,
                                                               Contact contactRec, 
                                                               String intAction, 
                                                               String intStatus,
                                                               String errorStatus,
                                                               String errorMessage,
                                                               String errorFields) {
        Diab_Integration_Log__c intLogRec = new Diab_Integration_Log__c();
        intLogRec.Integration_System__c = 'Sage';
        intLogRec.Integration_Type__c = 'Inbound';
        intLogRec.Unique_Key_Identifier__c = batchDateTime + '__' + contactRec.External_Id__c + '__' + contactRec.DIAB_MB_Team_Member_Code__c + '__' + contactRec.Department__c;
        intLogRec.Unique_Id_Field__c = 'Team Member Code';
        intLogRec.Unique_Id_Value__c = contactRec.DIAB_MB_Team_Member_Code__c;
        String recordJson = JSON.serialize(contactRec);
        recordJson = (recordJson != null && recordJson.length() > 131070) ? recordJson?.substring(0, 131070) : recordJson;
        intLogRec.Record_JSON__c = recordJson;
        intLogRec.Contact__c = contactRec.Id;
        intLogRec.Integration_Action__c = intAction;
        intLogRec.Integration_Status__c = intStatus;
        intLogRec.Error_Status_Code__c = errorStatus;
        errorMessage = (errorMessage != null && errorMessage.length() > 255) ? errorMessage?.substring(0, 254) : errorMessage;
        intLogRec.Error_Message__c = errorMessage;
        intLogRec.Error_Fields__c = errorFields;
        return intLogRec;
    } 

    private static Diab_Exception_Log__c createExceptionLogRecord(Id recordId, String statusCode, String errorMessage, List<String> fields){
        Diab_Exception_Log__c exl = new Diab_Exception_Log__c();
        exl.External_System_Name__c = 'Sage People';
        exl.Object_Name__c = 'Contact';
        exl.Object_Id__c = recordId?.toString();
        exl.Error_Status_Code__c = statusCode;
        errorMessage = (errorMessage != null && errorMessage.length() > 255) ? errorMessage?.substring(0, 254) : errorMessage;
        exl.Error_Message__c = errorMessage;
        exl.Error_Fields__c = fields?.toString();
        return exl;
    }
}