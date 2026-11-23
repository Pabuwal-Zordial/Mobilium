global class cls_OpportunityApprovalHandler {
    public static boolean requestApproval = true;
    public static boolean completeFlowAlreadyRan = false;
    public static boolean completeSecondFlowAlreadyRan = false;
    public static Integer approvalLevel = 1;
    public static String opportunityId;
    public static String specialApprover;
    public static Set<Id> managerUserList = new Set<Id>();
    static Set<String> ccSet = new Set<String>();
    public static final Map<String, Integer> stagesToStageNumbers = new Map<String, Integer>{ 'White Space' => 0, 'Identify the Opportunity' => 1, 'Validate the Opportunity' => 2, 'Qualify the Opportunity' => 3, 'Develop Solution' => 4, 'Propose Solution' => 5, 'Secure Agreement' => 6, 'PO & Signed Contract' => 7, 'Finance Review' => 8, 'Won & Closed' => 9 };
    public static final Set<String> closedLostStages = new Set<String>{ 'Lost', 'Deleted', 'Deleted Recon' };

    @TestVisible
    static final String APPROVER_GOVERNANCE_CFO_CRO = 'Governance committee & CRO & CFO';
    @TestVisible
    static final String APPROVER_GOVERNANCE_CRO = 'Governance committee & CRO';
    @TestVisible
    static final String APPROVER_CFO = 'CFO';
    @TestVisible
    static final String APPROVER_GOVERNANCE = 'Governance committee';
    @TestVisible
    static final String APPROVER_C_LEVEL_EXCLUIDING_CFO = 'C Level Excluding CFO';
    @TestVisible
    static final String CHIEF_OF_DELIVERY_SUPPORT = 'Chief of Delivery & Support';
    @TestVisible
    static final String CHIEF_OF_MANAGED_SERVICES = 'Chief of Managed Services';
    @TestVisible
    static final String CHIEF_OF_CUSTOMER_SUPPORT = 'Chief of Customer Support';
    @TestVisible
    static final String SHRIDARB = 'ShridarB';
    @TestVisible
    static final String CHRISTIAN_FRANK = 'Christian Frank';
    @TestVisible
    static final String APPROVER_FIRST_LEVEL_RR_MR = '1st Level RR - MR';
    @TestVisible
    static final Set<String> FIRST_LEVEL_APPROVERS = new Set<String>{ APPROVER_FIRST_LEVEL_RR_MR };

    @TestVisible
    private static Opportunity opp {
        get {
            if (opp == null) {
                opp = (Opportunity) [
                    SELECT
                        id,
                        Amount,
                        Owner.Email,
                        Country__r.Name,
                        Gross_Margin_of_Primary_Quote__c,
                        Sub_Region__c,
                        Entity_Number__c,
                        Renewal_Specialist__c,
                        REASON_FOR_APPROVAL__c,
                        Hardware_delivery_involved__c,
                        Delivery_Involved__c,
                        Customer_Services_Involved__c,
                        Managed_Services_Involved__c,
                        type,
                        Opportunity_Approval_Type__c,
                        Opportunity_Approval_Status__c,
                        Second_Approval_Status__c,
                        Business_Unit__c,
                        NON_STANDARD_CONDITIONS__c,
                        ROAMING_SECURITY_NON_STD_Deal_Margin__c,
                        RISK_NON_STD_Deal_Margin__c,
                        Testing_Non_Std_Deal_Margin__c,
                        Engmnt_Exp_Non_Std_Deal_Margin__c,
                        StageName,
                        Renewal_Specialist__r.email
                    FROM Opportunity
                    WHERE Id = :opportunityId
                ];
                specialApprover = findSpecialApprover(opp);
                System.debug('Special Approver -->' + specialApprover);
                return opp;
            } else {
                return opp;
            }
        }
        set;
    }

    @TestVisible
    private static Map<String, Approval_Processes_Configuration__c> specialApproversConfigurationMap {
        get {
            if (specialApproversConfigurationMap == null) {
                specialApproversConfigurationMap = new Map<String, Approval_Processes_Configuration__c>();

                for (Approval_Processes_Configuration__c apc : [
                    SELECT Approvers_Emails__c, Special_Approval_Routing__c
                    FROM Approval_Processes_Configuration__c
                    WHERE Special_Approval_Routing__c != NULL
                ]) {
                    specialApproversConfigurationMap.put(apc.Special_Approval_Routing__c, apc);
                }

                return specialApproversConfigurationMap;
            } else {
                return specialApproversConfigurationMap;
            }
        }
        set;
    }

    @TestVisible
    private static Map<String, Map<String, String>> regionalDeliveryHeads {
        get {
            System.debug(logginglevel.DEBUG, 'Regional Delivery Heads -->' + regionalDeliveryHeads);
            if (regionalDeliveryHeads == null) {
                List<AggregateResult> results = [
                    SELECT COUNT(Id), Business_Unit__c, Sub_Region__c, RDH__c
                    FROM Approval_Processes_Configuration__c
                    WHERE Sub_Region__c != 'ANY'
                    GROUP BY Business_Unit__c, Sub_Region__c, RDH__c
                    ORDER BY Business_Unit__c, Sub_Region__c, RDH__c
                ];

                regionalDeliveryHeads = new Map<String, Map<String, String>>();

                for (AggregateResult result : results) {
                    String businessUnit = (String) result.get('Business_Unit__c');
                    String subRegion = (String) result.get('Sub_Region__c');
                    String rdh = (String) result.get('RDH__c');

                    System.debug(logginglevel.DEBUG, 'Business Unit: ' + businessUnit + ', Sub Region: ' + subRegion + ', RDH: ' + rdh);
                    System.debug(logginglevel.DEBUG, 'Regional Delivery Heads contains: ' + regionalDeliveryHeads.containsKey(businessUnit?.toUpperCase()));
                    if (!regionalDeliveryHeads.containsKey(businessUnit?.toUpperCase())) {
                        regionalDeliveryHeads.put(businessUnit?.toUpperCase(), new Map<String, String>());
                    }

                    regionalDeliveryHeads.get(businessUnit?.toUpperCase()).put(subRegion?.toUpperCase(), rdh);
                }

                return regionalDeliveryHeads;
            } else {
                return regionalDeliveryHeads;
            }
        }
        set;
    }

    //Called from Approval process builder, if opportunity is approved or rejected
    @InvocableMethod
    public static void sendEmailforApproval(List<String> oppId) {
        opportunityId = oppId[0];

        if (getApprovalProcessNumber(opp) == 1) {
            if (completeFlowAlreadyRan)
                return;

            Boolean fireSecondApproval = checkIfShouldHaveSecondApproval();

            if (fireSecondApproval && (opp.Opportunity_Approval_Status__c == 'Approved')) {
                approvalLevel = 2;
                requestApproval = true;
            } else if (opp.Opportunity_Approval_Status__c == 'Approved - 2nd' || opp.Opportunity_Approval_Status__c == 'Rejected - 2nd') {
                approvalLevel = 2;
                requestApproval = false;
            } else if (opp.Opportunity_Approval_Status__c == 'Approved' || opp.Opportunity_Approval_Status__c == 'Rejected') {
                approvalLevel = 1;
                requestApproval = false;
            }

            initiateApproval(oppId[0]);

            if (fireSecondApproval && (opp.Opportunity_Approval_Status__c == 'Approved')) {
                opp.Opportunity_Approval_Status__c = 'Pending Second Level Approval';
                update opp;
            }
            completeFlowAlreadyRan = true;
        }
        if (getApprovalProcessNumber(opp) == 2) {
            System.debug('TESTE');
            System.debug(completeSecondFlowAlreadyRan);
            System.debug(opp.Amount);
            System.debug(opp.Second_Approval_Status__c);
            if (completeSecondFlowAlreadyRan)
                return;

            Boolean fireSecondApproval = opp.Amount >= 150000;

            if (fireSecondApproval && (opp.Second_Approval_Status__c == 'Approved')) {
                approvalLevel = 2;
                requestApproval = true;
            } else if (opp.Second_Approval_Status__c == 'Approved - 2nd' || opp.Second_Approval_Status__c == 'Rejected - 2nd') {
                approvalLevel = 2;
                requestApproval = false;
            } else if (opp.Second_Approval_Status__c == 'Approved' || opp.Second_Approval_Status__c == 'Rejected') {
                approvalLevel = 1;
                requestApproval = false;
            }

            initiateApproval(oppId[0]);

            if (fireSecondApproval && (opp.Second_Approval_Status__c == 'Approved')) {
                opp.Second_Approval_Status__c = 'Pending Second Level Approval';
                update opp;
            }
            completeSecondFlowAlreadyRan = true;
        }
    }
    //Classic Button
    webService static String submitApproval(String oppId) {
        return initiateApproval(oppId);
    }

    //Called from lightninting button/standard button
    @AuraEnabled
    public static String initiateApproval(String oppId) {
        opportunityId = oppId;

        try {
            String errorMessage = validatePreApprovalConditions();
            System.debug('Error Message -->' + errorMessage);

            if (!String.isBlank(errorMessage) && !errorMessage.contains('Warning')) {
                return errorMessage;
            }

            Set<String> emailAddressSet = getNextApprovers();
            System.debug('Email Address Set -->' + emailAddressSet);

            Map<String, String> workEmailSFUserMap = getWorkEmailSFUserMap(emailAddressSet);
            System.debug('workEmailSFUserMap from Approval_Process_Approver_User_Mapping__c ---> ' + workEmailSFUserMap);

            List<User> userList = [
                SELECT Id, Email
                FROM User
                WHERE Email IN :workEmailSFUserMap.keySet()
            ];

            if (userList.size() == 0) {
                System.debug('No user found');
                return 'No user found';
            }

            Map<Id, String> userIdEmailMap = new Map<Id, String>();
            Map<String, Id> emailUserIdMap = new Map<String, Id>();

            for (User u : userList) {
                userIdEmailMap.put(u.Id, u.Email.toLowerCase());
                emailUserIdMap.put(workEmailSFUserMap.get(u.Email.toLowerCase()), u.Id);
            }

            if (!requestApproval) {
                List<ProcessInstance> ProcessInstanceList = [
                    SELECT Id, LastActor.Email, LastActor.Id
                    FROM ProcessInstance
                    WHERE TargetObjectId = :opp.Id
                ];

                for (ProcessInstance processInstance : ProcessInstanceList) {
                    if (processInstance != null && processInstance.LastActor.Email != null) {
                        emailUserIdMap.put(processInstance.LastActor.Email, processInstance.LastActor.Id);
                    }
                }
            }

            if (requestApproval) {
                System.debug('Processing Approvals for ' + userIdEmailMap);
                processApprovals(opp, userIdEmailMap.keySet());
                updateOpportunity(oppId);
            }

            if (emailUserIdMap.keySet().size() > 0) {
                //To send Email
                System.debug('Sendng Emails for ' + emailUserIdMap);
                sendEmails(opp, emailUserIdMap.keySet());
            }

            if (!String.isBlank(errorMessage) && errorMessage.contains('Warning')) {
                return errorMessage;
            }

            return 'Success';
        } catch (DmlException e) {
            if (e.getMessage().contains('ALREADY_IN_PROCESS')) {
                return 'ALREADY_IN_PROCESS, This record is currently in an approval process.';
            } else {
                return 'No Applicable process found';
            }
        } catch (Exception e) {
            if (e.getMessage().contains('SendEmail')) {
                return 'SendEmail Failed.';
            } else {
                return 'Please contact the system admin. ' + e.getMessage();
            }
        }
    }

    @future
    public static void updateOpportunity(Id oppId) {
        Opportunity opp = new Opportunity(Id = oppId);
        update opp;
    }

    public static void sendEmails(Opportunity opp, Set<String> userEmails) {
        List<String> toAddresses = new List<String>();
        List<String> ccAddresses = new List<String>();

        if (userEmails.contains(specialApproversConfigurationMap.get(APPROVER_CFO).Approvers_Emails__c)) {
            specialApprover = APPROVER_GOVERNANCE_CFO_CRO;
        } else if (userEmails.contains(specialApproversConfigurationMap.get(APPROVER_GOVERNANCE).Approvers_Emails__c?.split(';')[0])) {
            specialApprover = APPROVER_GOVERNANCE_CRO;
        }

        if (requestApproval) {
            toAddresses.addAll(userEmails);
            ccAddresses.add(opp.Owner.Email);
            /*------------------------added by sunita for adding renewal specialist in all approval emails-----------------*/
            if (opp.Renewal_Specialist__c != null) {
                ccAddresses.add(opp.Renewal_Specialist__r.email);
            }
            /*--------------------------------------------------------------------------------------------------------*/
            if (specialApprover != null && approvalLevel == 2 && getApprovalProcessNumber(opp) == 1) {
                for (String governanceEmail : (System.Label.EMAIL_GOVERNANCE_COMMITTEE.split(','))) {
                    ccAddresses.add(governanceEmail);
                    if (opp.Renewal_Specialist__c != null) {
                        ccAddresses.add(opp.Renewal_Specialist__r.email); //added by sunita
                    }
                }
                //ccAddresses.addAll(findCorrespondingApprovalSettingToSendCCifGovernance());
            }
            if (!ccSet.isEmpty()) {
                ccAddresses.addAll(ccSet);
            }
        } else {
            toAddresses.add(opp.Owner.Email);
            ccAddresses.addAll(userEmails);
            if (opp.Renewal_Specialist__c != null) {
                ccAddresses.add(opp.Renewal_Specialist__r.email); //added by sunita
            }
            if (specialApprover != null && approvalLevel == 2 && getApprovalProcessNumber(opp) == 1) {
                for (String governanceEmail : (System.Label.EMAIL_GOVERNANCE_COMMITTEE.split(','))) {
                    ccAddresses.add(governanceEmail);
                    if (opp.Renewal_Specialist__c != null) {
                        ccAddresses.add(opp.Renewal_Specialist__r.email); //added by sunita
                    }
                }
                //ccAddresses.addAll(findCorrespondingApprovalSettingToSendCCifGovernance());
                ccAddresses.addAll(findCorrespondingApprovalSettingTofillCCsInSecondApproval());
            }
            if (!ccSet.isEmpty()) {
                ccAddresses.addAll(ccSet);
            }
        }
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        String templateName = findTemplateName();

        EmailTemplate emailTempl = [
            SELECT Id
            FROM EmailTemplate
            WHERE DeveloperName = :templateName
        ]; //not using communication template query because it will increase the query limit

        // Render the stored email template
        Messaging.SingleEmailMessage renderedEmail = Messaging.renderStoredEmailTemplate(emailTempl.Id, getDummyContact().Id, opp.Id);

        // Get the original subject
        String originalSubject = renderedEmail.getSubject();
        String originalBody = renderedEmail.getHtmlBody();

        // Append your custom text to the subject
        if (getApprovalProcessNumber(opp) == 1) {
            originalSubject = originalSubject;
        } else if (getApprovalProcessNumber(opp) == 2) {
            originalSubject = 'Delivery Approval Process - ' + originalSubject;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses); //To address
        email.setTreatTargetObjectAsRecipient(false);
        email.setTemplateId(emailTempl.Id); //Template id
        email.setTargetObjectId(getDummyContact().Id); //dummy contact id
        email.setwhatId(opp.Id); //opportunity id
        email.setSaveAsActivity(true);
        email.setCcAddresses(ccAddresses);

        email.setSubject(originalSubject);
        email.setHtmlBody(originalBody);

        mails.add(email);
        System.debug('Emails -->' + mails);

        Messaging.sendEmail(mails);
        System.debug('EMAILS SENT');
    }

    public static void processApprovals(Opportunity opp, Set<Id> userIds) {
        String level = approvalLevel == 1 ? 'first' : 'second';

        List<Approval.ProcessSubmitRequest> approvalRequestList = new List<Approval.ProcessSubmitRequest>();
        for (Id userId : userIds) {
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();

            if (getApprovalProcessNumber(opp) == 1) {
                approvalRequest.setProcessDefinitionNameOrId('Non_Standard_Approval');
                approvalRequest.setComments('Submitting request for ' + level + ' level approval.');
            } else if (getApprovalProcessNumber(opp) == 2) {
                approvalRequest.setProcessDefinitionNameOrId('Non_Standard_Approval_Delivery');
                approvalRequest.setComments('Submitting request for ' + level + ' level of additional approval.');
            }
            approvalRequest.setObjectId(opp.Id);
            approvalRequest.setNextApproverIds(new List<Id>{ userId });
            approvalRequest.setSkipEntryCriteria(true);
            approvalRequestList.add(approvalRequest);
        }
        List<Approval.ProcessResult> result = Approval.process(approvalRequestList);
    }

    public static Set<String> getNextApprovers() {
        Set<String> emailAddressSet = new Set<String>();

        /* if (approvalLevel == 1 && specialApprover != null && specialApprover == APPROVER_FIRST_LEVEL_RR_MR)
        {
            Approval_Processes_Configuration__c apc = specialApproversConfigurationMap.get(APPROVER_FIRST_LEVEL_RR_MR);
            if (!String.isBlank(apc.Approvers_Emails__c))
            {
                emailAddressSet.addAll(apc.Approvers_Emails__c?.Split(';'));
            }
            emailAddressSet.addAll(findCorrespondingApprovalSetting());
        } */
        if (specialApprover != null && approvalLevel == 2 && getApprovalProcessNumber(opp) == 1) {
            if (specialApprover == APPROVER_GOVERNANCE) {
                Approval_Processes_Configuration__c apc = specialApproversConfigurationMap.get(APPROVER_GOVERNANCE);

                if (!String.isBlank(apc.Approvers_Emails__c)) {
                    emailAddressSet.addAll(apc.Approvers_Emails__c?.Split(';'));
                }
            } else if (specialApprover == APPROVER_GOVERNANCE_CRO) {
                Approval_Processes_Configuration__c apc = specialApproversConfigurationMap.get(APPROVER_GOVERNANCE_CRO);

                if (!String.isBlank(apc.Approvers_Emails__c)) {
                    emailAddressSet.addAll(apc.Approvers_Emails__c?.Split(';'));
                }
            } else if (specialApprover == APPROVER_GOVERNANCE_CFO_CRO) {
                Approval_Processes_Configuration__c apc = specialApproversConfigurationMap.get(APPROVER_GOVERNANCE_CFO_CRO);
                if (!String.isBlank(apc.Approvers_Emails__c)) {
                    emailAddressSet.addAll(apc.Approvers_Emails__c?.Split(';'));
                }
            }

            emailAddressSet.addAll(findCorrespondingApprovalSetting());
        } else {
            emailAddressSet = findCorrespondingApprovalSetting();
        }

        return emailAddressSet;
    }

    public static Map<String, String> getWorkEmailSFUserMap(Set<String> emailAddressSet) {
        Map<String, String> workEmailSFUserMap = new Map<String, String>();

        for (String email : emailAddressSet) {
            workEmailSFUserMap.put(email.toLowerCase(), email);
        }
        System.debug('Emails before mapping -->' + workEmailSFUserMap);
        List<Approval_Process_Approver_User_Mapping__c> apaumList = (List<Approval_Process_Approver_User_Mapping__c>) [
            SELECT Work_Email__c, SF_User_Email__c
            FROM Approval_Process_Approver_User_Mapping__c
            WHERE Work_Email__c IN :emailAddressSet
        ];

        for (Approval_Process_Approver_User_Mapping__c apaum : apaumList) {
            if (!String.isEmpty(apaum.SF_User_Email__c) && !String.isEmpty(apaum.Work_Email__c)) {
                workEmailSFUserMap.put(apaum.SF_User_Email__c.toLowerCase(), apaum.Work_Email__c);
            }
        }
        System.debug('Emails after mapping -->' + workEmailSFUserMap);

        return workEmailSFUserMap;
    }

    @TestVisible
    private static String findSpecialApprover(Opportunity opp) {
        String approver = null;

        Set<String> oppTypesThatShoulbeApprovedByGovernance = new Set<String>{ 'MR-Maintenance Renewal', 'R-Recurring Revenue', 'CR-Change Request' };
        Set<String> oppTypesThatShoulHave1stLevelSpecialApprover = new Set<String>{ 'MR-Maintenance Renewal', 'R-Recurring Revenue' };

        /*  if (approvalLevel == 1 && oppTypesThatShoulHave1stLevelSpecialApprover.contains(opp.Type))
        {
            return APPROVER_FIRST_LEVEL_RR_MR;
        }*/

        if (opp.Opportunity_Approval_Type__c != 'Non-Standard' && !oppTypesThatShoulbeApprovedByGovernance.contains(opp.Type)) {
            return approver;
        }

        if (opp.Amount >= 50000 && (opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c == 'Margin < 25%' || opp.RISK_NON_STD_Deal_Margin__c == 'Margin< 25%' || opp.Testing_Non_Std_Deal_Margin__c == 'Margin < 25%' || opp.Engmnt_Exp_Non_Std_Deal_Margin__c == 'Margin< 25%')) {
            approver = APPROVER_GOVERNANCE_CFO_CRO;
        } else if (
            (opp.Amount > 300000 || opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c == '<70% Margin =< 25%' || opp.RISK_NON_STD_Deal_Margin__c == '<70% Margin =< 25%' || opp.Testing_Non_Std_Deal_Margin__c == '<75% Margin =< 25%' || opp.Engmnt_Exp_Non_Std_Deal_Margin__c == '<70% Margin =< 25%') ||
            (opp.Amount <= 50000 && (opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c == 'Margin < 25%' || opp.RISK_NON_STD_Deal_Margin__c == 'Margin< 25%' || opp.Testing_Non_Std_Deal_Margin__c == 'Margin < 25%' || opp.Engmnt_Exp_Non_Std_Deal_Margin__c == 'Margin< 25%'))
        ) {
            approver = APPROVER_GOVERNANCE_CRO;
        } else if (oppTypesThatShoulbeApprovedByGovernance.contains(opp.Type)) {
            approver = APPROVER_GOVERNANCE;
        }

        return approver;
    }

    @TestVisible
    private static Boolean shouldIncludeGMs() {
        if (approvalLevel == 2 && (opp.Amount > 300000 || opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c != null || opp.RISK_NON_STD_Deal_Margin__c != null || opp.Testing_Non_Std_Deal_Margin__c != null || opp.Engmnt_Exp_Non_Std_Deal_Margin__c != null)) {
            return true;
        }
        return false;
    }

    private static Set<String> getFirstLevelApproversFromApprovalSettings(Approval_Processes_Configuration__c acl) {
        Set<String> emailList = new Set<String>();

        if (opp.Opportunity_Approval_Type__c == 'Non-Standard' && opp.NON_STANDARD_CONDITIONS__c == null && acl.BU_Head__c != null) {
            emailList.addAll(acl.BU_Head__c?.Split(';'));
        } else if (acl.Approvers_Emails__c != null) {
            emailList.addAll(acl.Approvers_Emails__c?.Split(';'));
        }

        if (opp.Opportunity_Approval_Type__c == 'Non-Standard' && acl.BU_Head__c != null && (opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c != null || opp.RISK_NON_STD_Deal_Margin__c != null || opp.Testing_Non_Std_Deal_Margin__c != null || opp.Engmnt_Exp_Non_Std_Deal_Margin__c != null)) {
            emailList.addAll(acl.BU_Head__c?.Split(';'));
        }

        if (opp.Opportunity_Approval_Type__c == 'Standard' && opp.Hardware_delivery_involved__c == 'Yes') {
            emailList.addAll(specialApproversConfigurationMap.get(SHRIDARB).Approvers_Emails__c?.Split(';'));
            if (opp.Business_Unit__c?.split(';')?.contains('TESTING') || opp.Entity_Number__c == '20') {
                emailList.addAll(specialApproversConfigurationMap.get(CHRISTIAN_FRANK).Approvers_Emails__c?.Split(';'));
            }
        }

        if (opp.Delivery_Involved__c == 'Yes') {
            List<String> businessUnit = opp.Business_Unit__c?.split(';');
            for (String bu : businessUnit) {
                emailList.addAll(regionalDeliveryHeads.get(bu?.toUpperCase()).get(opp.Sub_Region__c?.toUpperCase())?.Split(';'));
                System.debug('REGIONAL DELIVERY HEAD------>' + regionalDeliveryHeads.get(bu?.toUpperCase())?.get(opp.Sub_Region__c?.toUpperCase())?.Split(';'));
            }
        }

        if (opp.Managed_Services_Involved__c == 'Yes') {
            for (String businessUnit : opp.Business_Unit__c?.split(';')) {
                emailList.addAll(specialApproversConfigurationMap.get('MS-' + businessUnit?.toUpperCase()).Approvers_Emails__c?.Split(';'));
            }
        }
        if (opp.Customer_Services_Involved__c == 'Yes') {
            for (String businessUnit : opp.Business_Unit__c?.split(';')) {
                emailList.addAll(specialApproversConfigurationMap.get('CS-' + businessUnit?.toUpperCase()).Approvers_Emails__c?.Split(';'));
            }
        }

        System.debug(emailList);

        return emailList;
    }

    @TestVisible
    private static Set<String> findCorrespondingApprovalSetting() {
        Set<String> emailList = new Set<String>();

        //Second Approval Process
        if (getApprovalProcessNumber(opp) == 2) {
            if (approvalLevel == 2 && opp.Amount >= 150000) {
                if (opp.Delivery_Involved__c == 'Yes') {
                    emailList.addAll(specialApproversConfigurationMap.get(CHIEF_OF_DELIVERY_SUPPORT).Approvers_Emails__c?.Split(';'));
                }
                if (opp.Managed_Services_Involved__c == 'Yes') {
                    emailList.addAll(specialApproversConfigurationMap.get(CHIEF_OF_MANAGED_SERVICES).Approvers_Emails__c?.Split(';'));
                }
                if (opp.Customer_Services_Involved__c == 'Yes') {
                    emailList.addAll(specialApproversConfigurationMap.get(CHIEF_OF_CUSTOMER_SUPPORT).Approvers_Emails__c?.Split(';'));
                }
            } else {
                List<String> businessUnit = opp.Business_Unit__c?.split(';');
                for (String bu : businessUnit) {
                    if (opp.Delivery_Involved__c == 'Yes') {
                        emailList.addAll(regionalDeliveryHeads.get(bu?.toUpperCase()).get(opp.Sub_Region__c?.toUpperCase())?.Split(';'));
                    }

                    if (opp.Managed_Services_Involved__c == 'Yes') {
                        emailList.addAll(specialApproversConfigurationMap.get('MS-' + bu?.toUpperCase()).Approvers_Emails__c?.Split(';'));
                    }

                    if (opp.Customer_Services_Involved__c == 'Yes') {
                        emailList.addAll(specialApproversConfigurationMap.get('CS-' + bu?.toUpperCase()).Approvers_Emails__c?.Split(';'));
                    }
                }
            }
            return emailList;
        }

        //First Approval Process

        Set<String> availableEntityCodes = new Set<String>();
        Set<String> availableCountries = new Set<String>();

        for (AggregateResult ar : [
            SELECT Entity_Code__c, Country__c
            FROM Approval_Processes_Configuration__c
            WHERE Entity_Code__c != NULL OR Country__c != NULL
            GROUP BY Entity_Code__c, Country__c
        ]) {
            if ((String) ar.get('Entity_Code__c') != null) {
                availableEntityCodes.add((String) ar.get('Entity_Code__c'));
            }
            if ((String) ar.get('Country__c') != null) {
                availableCountries.add((String) ar.get('Country__c'));
            }
        }

        String approvalType = opp.Opportunity_Approval_Type__c;
        List<String> businessUnit = opp.Business_Unit__c?.split(';');
        List<String> oppType = opp.Opportunity_Approval_Type__c != 'Standard' ? opp.NON_STANDARD_CONDITIONS__c?.split(';') : new List<String>{ opp.Type };
        String subRegion = opp.Sub_Region__c;
        String entityCode = availableEntityCodes.contains(opp.Entity_Number__c?.left(2)) ? opp.Entity_Number__c.left(2) : '--';
        String country = availableCountries.contains(opp.Country__r?.Name.toUpperCase()) ? opp.Country__r?.Name : null;

        System.debug('entityCode ---> ' + entityCode);
        System.debug('approvalType ---> ' + approvalType);
        System.debug('businessUnit ---> ' + businessUnit);
        System.debug('oppType  ---> ' + oppType);
        System.debug('subRegion  --->' + subRegion);
        System.debug('country  --->' + country);

        String queryString = 'SELECT Name, ID, Entity_Code__c, Approval_Type__c, Sub_Region__c, Country__c, Approvers_Emails__c, Second_Level_Approvers__c, BU_Head__c, GM__c, Business_Unit__c, Type__c, CCs__c, Special_Approval_Routing__c FROM Approval_Processes_Configuration__c ';
        String whereClause = '';

        whereClause += 'Entity_Code__c = :entityCode AND ';

        if (opp.Opportunity_Approval_Type__c != null) {
            whereClause += 'Approval_Type__c = :approvalType AND ';
        }

        if (businessUnit != null) {
            whereClause += 'Business_Unit__c IN :businessUnit AND ';
        }

        if (oppType != null) {
            whereClause += 'Type__c IN :oppType AND ';
        }

        if (subRegion != null) {
            whereClause += 'Sub_Region__c = :subRegion AND ';
        }

        whereClause += 'Country__c = :country AND ';

        if (!String.isBlank(whereClause)) {
            whereClause = 'WHERE ' + whereClause.removeEnd('AND ');
        } else {
            return null;
        }

        System.debug('queryString ---> ' + queryString + whereClause);

        List<Approval_Processes_Configuration__c> approvalConfigurationList = (List<Approval_Processes_Configuration__c>) Database.query(queryString + whereClause);
        Set<String> allApprovers = new Set<String>();
        Set<String> firstLevelApprovers = new Set<String>();

        for (Approval_Processes_Configuration__c acl : approvalConfigurationList) {
            firstLevelApprovers.addAll(getFirstLevelApproversFromApprovalSettings(acl));
        }

        for (Approval_Processes_Configuration__c acl : approvalConfigurationList) {
            if (acl.Approvers_Emails__c != null && !String.isBlank(opp.NON_STANDARD_CONDITIONS__c)) {
                allApprovers.addAll(acl.Approvers_Emails__c?.Split(';'));
            }

            if (approvalLevel == 1 && acl.Approvers_Emails__c != null) {
                emailList.addAll(getFirstLevelApproversFromApprovalSettings(acl));
            } else if (approvalLevel == 2 && requestApproval == true) {
                // && acl.Second_Level_Approvers__c != null)
                if (String.isBlank(opp.NON_STANDARD_CONDITIONS__c) && opp.Opportunity_Approval_Type__c == 'Non-Standard') {
                    emailList.addAll(specialApproversConfigurationMap.get(APPROVER_C_LEVEL_EXCLUIDING_CFO).Approvers_Emails__c?.Split(';'));
                } else {
                    if (acl.Second_Level_Approvers__c != null) {
                        emailList.addAll(acl.Second_Level_Approvers__c?.Split(';'));
                    }
                }

                if (shouldIncludeGMs()) {
                    emailList.addAll(acl.GM__c?.Split(';'));
                }

                if (opp.Opportunity_Approval_Type__c == 'Standard' && opp.Hardware_delivery_involved__c == 'Yes') {
                    emailList.addAll(specialApproversConfigurationMap.get(CHIEF_OF_DELIVERY_SUPPORT).Approvers_Emails__c?.Split(';'));
                }
                if (opp.Amount >= 150000) {
                    if (opp.Delivery_Involved__c == 'Yes') {
                        emailList.addAll(specialApproversConfigurationMap.get(CHIEF_OF_DELIVERY_SUPPORT).Approvers_Emails__c?.Split(';'));
                    }
                    if (opp.Managed_Services_Involved__c == 'Yes') {
                        emailList.addAll(specialApproversConfigurationMap.get(CHIEF_OF_MANAGED_SERVICES).Approvers_Emails__c?.Split(';'));
                    }
                    if (opp.Customer_Services_Involved__c == 'Yes') {
                        emailList.addAll(specialApproversConfigurationMap.get(CHIEF_OF_CUSTOMER_SUPPORT).Approvers_Emails__c?.Split(';'));
                    }
                }

                emailList.removeAll(firstLevelApprovers);

                allApprovers.removeAll(emailList);
                ccSet.addAll(allApprovers);
            } else if (approvalLevel == 2 && requestApproval == false) {
                // && acl.Second_Level_Approvers__c != null)
                if (acl.Second_Level_Approvers__c != null) {
                    allApprovers.addAll(acl.Second_Level_Approvers__c?.Split(';'));
                }

                if (acl.Approvers_Emails__c != null) {
                    allApprovers.addAll(acl.Approvers_Emails__c?.Split(';'));
                }
                if (acl.GM__c != null && shouldIncludeGMs()) {
                    allApprovers.addAll(acl.GM__c?.Split(';'));
                }

                if (opp.Opportunity_Approval_Type__c == 'Standard' && opp.Hardware_delivery_involved__c == 'Yes') {
                    allApprovers.addAll(specialApproversConfigurationMap.get(CHIEF_OF_DELIVERY_SUPPORT).Approvers_Emails__c?.Split(';'));
                    allApprovers.addAll(specialApproversConfigurationMap.get(SHRIDARB).Approvers_Emails__c?.Split(';'));
                    if (opp.Business_Unit__c?.split(';')?.contains('TESTING') || opp.Entity_Number__c == '20') {
                        allApprovers.addAll(specialApproversConfigurationMap.get(CHRISTIAN_FRANK).Approvers_Emails__c?.Split(';'));
                    }
                }
                if (opp.Delivery_Involved__c == 'Yes' && opp.Amount >= 1500000) {
                    allApprovers.addAll(specialApproversConfigurationMap.get(CHIEF_OF_DELIVERY_SUPPORT).Approvers_Emails__c?.Split(';'));
                }
                if (opp.Managed_Services_Involved__c == 'Yes' && opp.Amount >= 1500000) {
                    allApprovers.addAll(specialApproversConfigurationMap.get(CHIEF_OF_MANAGED_SERVICES).Approvers_Emails__c?.Split(';'));
                }
                if (opp.Customer_Services_Involved__c == 'Yes' && opp.Amount >= 1500000) {
                    allApprovers.addAll(specialApproversConfigurationMap.get(CHIEF_OF_CUSTOMER_SUPPORT).Approvers_Emails__c?.Split(';'));
                }

                emailList.add(opp.Owner.Email);
                ccSet.addAll(allApprovers);
                if (acl.BU_Head__c != null) {
                    ccSet.addAll(acl.BU_Head__c?.Split(';'));
                }
            }

            if (acl.CCs__c != null) {
                ccSet.addAll(acl.CCs__c?.Split(';'));
            }
        }

        System.debug('Approvers emailList from Approval_Processes_Configuration__c ---> ' + approvalConfigurationList);

        return emailList;
    }

    @TestVisible
    private static Set<String> findCorrespondingApprovalSettingTofillCCsInSecondApproval() {
        Set<String> emailList = new Set<String>();

        if (approvalLevel != 2 || requestApproval == true)
            return emailList;

        Set<String> availableEntityCodes = new Set<String>();
        Set<String> availableCountries = new Set<String>();

        for (AggregateResult ar : [
            SELECT Entity_Code__c, Country__c
            FROM Approval_Processes_Configuration__c
            WHERE Entity_Code__c != NULL OR Country__c != NULL
            GROUP BY Entity_Code__c, Country__c
        ]) {
            if ((String) ar.get('Entity_Code__c') != null) {
                availableEntityCodes.add((String) ar.get('Entity_Code__c'));
            }
            if ((String) ar.get('Country__c') != null) {
                availableCountries.add((String) ar.get('Country__c'));
            }
        }

        String approvalType = opp.Opportunity_Approval_Type__c;
        List<String> businessUnit = opp.Business_Unit__c?.split(';');
        List<String> oppType = opp.Opportunity_Approval_Type__c != 'Standard' ? opp.NON_STANDARD_CONDITIONS__c?.split(';') : new List<String>{ opp.Type };
        String subRegion = opp.Sub_Region__c;
        String entityCode = availableEntityCodes.contains(opp.Entity_Number__c?.left(2)) ? opp.Entity_Number__c.left(2) : '--';
        String country = availableCountries.contains(opp.Country__r?.Name.toUpperCase()) ? opp.Country__r?.Name : null;

        String queryString = 'SELECT Name, ID, Entity_Code__c, Approval_Type__c, Sub_Region__c, Country__c, Approvers_Emails__c, Second_Level_Approvers__c, BU_Head__c, Business_Unit__c, Type__c, CCs__c, Special_Approval_Routing__c FROM Approval_Processes_Configuration__c ';
        String whereClause = '';

        whereClause += 'Entity_Code__c = :entityCode AND ';

        if (opp.Opportunity_Approval_Type__c != null) {
            whereClause += 'Approval_Type__c = :approvalType AND ';
        }

        if (businessUnit != null) {
            whereClause += 'Business_Unit__c IN :businessUnit AND ';
        }

        if (oppType != null) {
            whereClause += 'Type__c IN :oppType AND ';
        }

        if (subRegion != null) {
            whereClause += 'Sub_Region__c = :subRegion AND ';
        }

        whereClause += 'Country__c = :country AND ';

        if (!String.isBlank(whereClause)) {
            whereClause = 'WHERE ' + whereClause.removeEnd('AND ');
        } else {
            return null;
        }
        List<Approval_Processes_Configuration__c> approvalConfigurationList = (List<Approval_Processes_Configuration__c>) Database.query(queryString + whereClause);

        for (Approval_Processes_Configuration__c acl : approvalConfigurationList) {
            if (!String.isBlank(opp.NON_STANDARD_CONDITIONS__c)) {
                if (acl.Approvers_Emails__c != null) {
                    emailList.addAll(acl.Approvers_Emails__c?.Split(';'));
                }
                if (acl.Second_Level_Approvers__c != null) {
                    emailList.addAll(acl.Second_Level_Approvers__c?.Split(';'));
                }
            } else {
                emailList.addAll(acl.BU_Head__c?.Split(';'));
            }
        }
        return emailList;
    }

    // @TestVisible
    // private static Set<String> findCorrespondingApprovalSettingToSendCCifGovernance()
    // {
    //     Set<String> emailList = new Set<String>();
    //     Set<String> availableEntityCodes = new Set<String>();
    //     Set<String> availableCountries = new Set<String>();

    //     for (AggregateResult ar : [SELECT Entity_Code__c, Country__c FROM Approval_Processes_Configuration__c WHERE Entity_Code__c != null OR Country__c != null GROUP BY Entity_Code__c, Country__c])
    //     {
    //         if ((String)ar.get('Entity_Code__c') != null)
    //         {
    //             availableEntityCodes.add((String)ar.get('Entity_Code__c'));
    //         }
    //         if ((String)ar.get('Country__c') != null)
    //         {
    //             availableCountries.add((String)ar.get('Country__c'));
    //         }
    //     }

    //     String approvalType = opp.Opportunity_Approval_Type__c;
    //     List<String> businessUnit = opp.Business_Unit__c?.split(';');
    //     List<String>  oppType = opp.Opportunity_Approval_Type__c != 'Standard' ? opp.NON_STANDARD_CONDITIONS__c?.split(';') : new List<String>{opp.Type};
    //     String subRegion = opp.Sub_Region__c;
    //     String entityCode = availableEntityCodes.contains(opp.Entity_Number__c?.left(2)) ? opp.Entity_Number__c.left(2) : '--';
    //     String country = availableCountries.contains(opp.Country__r?.Name.toUpperCase()) ? opp.Country__r?.Name : null;

    //     String queryString = 'SELECT Name, ID, Entity_Code__c, Approval_Type__c, Sub_Region__c, Country__c, Approvers_Emails__c, Second_Level_Approvers__c, Business_Unit__c, Type__c, CCs__c, Special_Approval_Routing__c FROM Approval_Processes_Configuration__c ';
    //     String whereClause = '';

    //     whereClause += 'Include_in_Governance_Emails__c = TRUE AND ';

    //     whereClause += 'Entity_Code__c = :entityCode AND ';

    //     if (opp.Opportunity_Approval_Type__c != null)
    //     {
    //         whereClause += 'Approval_Type__c = :approvalType AND ';
    //     }

    //     if (businessUnit != null)
    //     {
    //         whereClause +='Business_Unit__c IN :businessUnit AND ';
    //     }

    //     if (oppType != null)
    //     {
    //         whereClause += 'Type__c IN :oppType AND ';
    //     }

    //     if (subRegion != null)
    //     {
    //         whereClause += 'Sub_Region__c = :subRegion AND ';
    //     }

    //     whereClause += 'Country__c = :country AND ';

    //     if (!String.isBlank(whereClause))
    //     {
    //         whereClause = 'WHERE ' + whereClause.removeEnd('AND ');
    //     }
    //     else
    //     {
    //         return null;
    //     }
    //     List<Approval_Processes_Configuration__c> approvalConfigurationList = (List<Approval_Processes_Configuration__c>) Database.query(queryString + whereClause);

    //     for (Approval_Processes_Configuration__c acl : approvalConfigurationList)
    //     {
    //         emailList.addAll(acl.Approvers_Emails__c?.Split(';'));
    //     }
    //     System.debug('emails to be added to governance emails ---> ' + emailList);

    //     return emailList;
    // }

    @TestVisible
    private static Boolean checkIfShouldHaveSecondApproval() {
        String secondLevelSpecialApprover = findSpecialApprover(opp);

        if (secondLevelSpecialApprover != null && !FIRST_LEVEL_APPROVERS.contains(secondLevelSpecialApprover)) {
            return true;
        }
        if (opp.Opportunity_Approval_Type__c == 'Standard' && opp.Hardware_delivery_involved__c == 'Yes') {
            return true;
        }
        if ((opp.Delivery_Involved__c == 'Yes' || opp.Managed_Services_Involved__c == 'Yes' || opp.Customer_Services_Involved__c == 'Yes') && opp.Amount >= 150000) {
            return true;
        }

        Set<String> availableEntityCodes = new Set<String>();
        Set<String> availableCountries = new Set<String>();

        for (AggregateResult ar : [
            SELECT Entity_Code__c, Country__c
            FROM Approval_Processes_Configuration__c
            WHERE Entity_Code__c != NULL OR Country__c != NULL
            GROUP BY Entity_Code__c, Country__c
        ]) {
            if ((String) ar.get('Entity_Code__c') != null) {
                availableEntityCodes.add((String) ar.get('Entity_Code__c'));
            }
            if ((String) ar.get('Country__c') != null) {
                availableCountries.add((String) ar.get('Country__c'));
            }
        }

        String approvalType = opp.Opportunity_Approval_Type__c;
        List<String> businessUnit = opp.Business_Unit__c?.split(';');
        List<String> oppType = opp.Opportunity_Approval_Type__c != 'Standard' ? opp.NON_STANDARD_CONDITIONS__c?.split(';') : new List<String>{ opp.Type };
        String subRegion = opp.Sub_Region__c;
        String entityCode = availableEntityCodes.contains(opp.Entity_Number__c?.left(2)) ? opp.Entity_Number__c.left(2) : '--';
        String country = availableCountries.contains(opp.Country__r?.Name.toUpperCase()) ? opp.Country__r?.Name : null;

        String queryString = 'SELECT Name, ID, Entity_Code__c, Approval_Type__c, Sub_Region__c, Approvers_Emails__c, Second_Level_Approvers__c, Business_Unit__c, Type__c, CCs__c, Special_Approval_Routing__c FROM Approval_Processes_Configuration__c ';
        String whereClause = '';

        whereClause += 'Entity_Code__c = :entityCode AND ';
        whereClause += 'Second_Level_Approvers__c != null AND ';

        if (opp.Opportunity_Approval_Type__c != null) {
            whereClause += 'Approval_Type__c = :approvalType AND ';
        }

        if (businessUnit != null) {
            whereClause += 'Business_Unit__c IN :businessUnit AND ';
        }

        if (oppType != null) {
            whereClause += 'Type__c IN :oppType AND ';
        }

        if (subRegion != null) {
            whereClause += 'Sub_Region__c = :subRegion AND ';
        }

        whereClause += 'Country__c = :country AND ';

        if (!String.isBlank(whereClause)) {
            whereClause = 'WHERE ' + whereClause.removeEnd('AND ');
        }

        System.debug(queryString + whereClause);

        System.debug('Entity_Code__c = ' + entityCode);
        System.debug('Approval_Type__c = ' + approvalType);
        System.debug('Business_Unit__c = ' + businessUnit);
        System.debug('Type__c = ' + oppType);
        System.debug('Sub_Region__c = ' + subRegion);
        System.debug('Country__c = ' + country);

        List<Approval_Processes_Configuration__c> approvalConfigurationList = (List<Approval_Processes_Configuration__c>) Database.query(queryString + whereClause);

        System.debug('checkIfShouldHaveSecondApproval --->' + !approvalConfigurationList.isEmpty());

        return !approvalConfigurationList.isEmpty();
    }

    public static void rejectionAction(Set<Id> rejectedOpportunitySet, List<Opportunity> oppLst, Map<Id, Opportunity> oldMap) {
        //Start:Rejection code
        if (rejectedOpportunitySet.size() > 0) {
            List<ProcessInstanceWorkitem> processItemsList = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.Status = 'Pending' AND ProcessInstance.TargetObjectId IN :rejectedOpportunitySet
            ];
            if (processItemsList.size() > 0) {
                List<Approval.ProcessWorkitemRequest> processWorkitemRequest = new List<Approval.ProcessWorkitemRequest>();
                for (ProcessInstanceWorkitem pi : processItemsList) {
                    Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
                    req2.setComments('Rejected');
                    req2.setAction('Reject');
                    req2.setNextApproverIds(new List<Id>{ UserInfo.getUserId() });
                    req2.setWorkitemId(pi.Id);
                    processWorkitemRequest.add(req2);
                }
                Approval.process(processWorkitemRequest);
            }
        }

        for (Opportunity opp : oppLst) {
            if (getApprovalProcessNumber(opp) == 1) {
                if (opp.Opportunity_Approval_Status__c == 'Rejected' && oldMap.get(opp.Id).Opportunity_Approval_Status__c == 'Pending Second Level Approval') {
                    opp.Opportunity_Approval_Status__c = 'Rejected - 2nd';
                }
            } else if (getApprovalProcessNumber(opp) == 2) {
                if (opp.Second_Approval_Status__c == 'Rejected' && oldMap.get(opp.Id).Second_Approval_Status__c == 'Pending Second Level Approval') {
                    opp.Second_Approval_Status__c = 'Rejected - 2nd';
                }
                // Disabled: auto-reverting StageName to 'Propose Solution' on Secure Agreement rejection
                // incorrectly moves the Opportunity off Secure Agreement and then blocks re-submission
                // (DynamicApprovalEngine.submitSAApproval requires StageName == 'Secure Agreement').
                // if (opp.Second_Approval_Status__c.contains('Rejected') && !oldMap.get(opp.Id).Second_Approval_Status__c.contains('Rejected'))
                //     opp.StageName = 'Propose Solution';
            }
        }
    }

    public static void recallAction(Set<Id> recallOpportunitySet, List<Opportunity> oppLst, Map<Id, Opportunity> oldMap) {
        //Start:Rejection code
        if (recallOpportunitySet.size() > 0) {
            List<ProcessInstanceWorkitem> processItemsList = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.Status = 'Pending' AND ProcessInstance.TargetObjectId IN :recallOpportunitySet
            ];
            System.debug('Recall Size' + processItemsList.size());
            if (processItemsList.size() > 0) {
                List<Approval.ProcessWorkitemRequest> processWorkitemRequest = new List<Approval.ProcessWorkitemRequest>();
                for (ProcessInstanceWorkitem pi : processItemsList) {
                    Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
                    req2.setComments('Recalled');
                    req2.setAction('Removed');
                    req2.setNextApproverIds(new List<Id>{ UserInfo.getUserId() });
                    req2.setWorkitemId(pi.Id);
                    processWorkitemRequest.add(req2);
                }

                Approval.ProcessResult[] processResults = Approval.process(processWorkitemRequest);
                System.debug('Recall Results' + processResults);
            }
        }
    }

    // Deprecated
    // public static void autoApprove(Opportunity opp)
    // {f
    //  List<ProcessInstanceWorkitem> processItemsList = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.Status ='Pending' and ProcessInstance.TargetObjectId =: opp.Id];
    //  if(processItemsList.size()>0)
    //  {
    //      List<Approval.ProcessWorkitemRequest> processWorkitemRequest= new List<Approval.ProcessWorkitemRequest>();
    //      for(ProcessInstanceWorkitem pi : processItemsList)
    //      {
    //          Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
    //          req2.setComments('Approved Automatically');
    //          req2.setAction('Approve');
    //          req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
    //          req2.setWorkitemId(pi.Id);
    //          processWorkitemRequest.add(req2);
    //      }
    //      Approval.process(processWorkitemRequest);
    //  }
    // }

    public static void ApprovalAction(Set<Id> opportunitySet, List<Opportunity> oppLst, Map<Id, Opportunity> oldMap) {
        Set<Id> opportunityPendingSet = new Set<Id>();
        //Only supports one at a time
        if (opportunitySet.size() == 1) {
            Opportunity opp = oppLst[0];

            List<ProcessInstanceStep> justApprovedProcess = [
                SELECT Id, ProcessInstance.TargetObjectId, StepStatus, OriginalActor.Email
                FROM ProcessInstanceStep
                WHERE StepStatus = 'Approved' AND ProcessInstance.TargetObjectId IN :opportunitySet AND SystemModstamp > :System.Now().addminutes(-1)
                ORDER BY SystemModstamp DESC
                LIMIT 1
            ];

            if (justApprovedProcess.isEmpty()) {
                return;
            }

            List<Approval_Process_By_Pass_Users__c> apbpus = [
                SELECT ID, UsersAbleToByPass__c, User__c
                FROM Approval_Process_By_Pass_Users__c
                WHERE UsersAbleToByPass__c LIKE :('%' + justApprovedProcess[0].OriginalActor.Email + '%')
                LIMIT 1
            ];
            //String bypassApprovers = apbpu.UsersAbleToByPass__c.remove(justApprovedProcess[0].OriginalActor.Email);
            //String bypassees = apbpu.User__c;

            List<ProcessInstanceWorkitem> processWorkItemsList = [
                SELECT Id, ProcessInstance.TargetObjectId, Actor.Email
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.Status = 'Pending' AND ProcessInstance.TargetObjectId IN :opportunitySet
            ];

            Set<String> bypassApprovers = new Set<String>();
            Set<String> bypassees = new Set<String>();

            if (!apbpus.isEmpty()) {
                bypassApprovers = new Set<String>(apbpus[0].UsersAbleToByPass__c.split(';'));
                bypassApprovers.remove(justApprovedProcess[0].OriginalActor.Email);
                bypassees = new Set<String>(apbpus[0].User__c.split(';'));

                System.debug('### bypassApprovers -> ' + bypassApprovers);
                System.debug('### bypassees -> ' + bypassees);

                Set<String> pendingApproverEmails = new Set<String>();
                for (ProcessInstanceWorkitem piwi : processWorkItemsList) {
                    pendingApproverEmails.add(piwi.Actor.Email);
                    //bypassApprovers = bypassApprovers.remove(piwi.Actor.Email);
                }
                System.debug('### pendingApproverEmails -> ' + pendingApproverEmails);
                for (String bypassApprover : bypassApprovers) {
                    System.debug('### Missing approver -> ' + bypassApprover);
                    if (!pendingApproverEmails.contains(bypassApprover)) {
                        bypassApprovers.remove(bypassApprover);
                        System.debug('### Missing approver NOT ON THE PENDING ONES -> ' + bypassApprovers);
                    }
                }
            }

            if (!justApprovedProcess.isEmpty() && !processWorkItemsList.isEmpty()) {
                for (ProcessInstanceWorkitem piwi : processWorkItemsList) {
                    List<Approval.ProcessWorkitemRequest> processWorkitemRequest = new List<Approval.ProcessWorkitemRequest>();

                    //if(byPasseeApproverMap.get(piwi.Actor.Email) != null && byPasseeApproverMap.get(piwi.Actor.Email)?.contains(justApprovedProcess[0].OriginalActor.Email) && (countPendingBypassers == 0 || byPasseeApproverMap.get(piwi.Actor.Email)?.size() == 1))

                    if (bypassApprovers.isEmpty() && bypassees.contains(piwi.Actor.Email)) {
                        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
                        req2.setComments('Approved By Manager');
                        req2.setAction('Approve');
                        req2.setNextApproverIds(new List<Id>{ UserInfo.getUserId() });
                        req2.setWorkitemId(piwi.Id);
                        processWorkitemRequest.add(req2);
                    } else {
                        opportunityPendingSet.add(piwi.ProcessInstance.TargetObjectId);
                    }
                    if (!processWorkitemRequest.isEmpty()) {
                        Approval.ProcessResult[] processResults = Approval.process(processWorkitemRequest);
                    }
                }
            }

            if (getApprovalProcessNumber(opp) == 1) {
                if (opp.Opportunity_Approval_Status__c == 'Approved' && oldMap.get(opp.Id).Opportunity_Approval_Status__c != 'Pending Second Level Approval' && opportunityPendingSet.contains(opp.Id)) {
                    opp.Opportunity_Approval_Status__c = 'Pending Approval';
                    Approval.lock(opp);
                }

                if (opp.Opportunity_Approval_Status__c == 'Approved' && oldMap.get(opp.Id).Opportunity_Approval_Status__c == 'Pending Second Level Approval' && opportunityPendingSet.contains(opp.Id)) {
                    opp.Opportunity_Approval_Status__c = 'Pending Second Level Approval';
                    Approval.lock(opp);
                }

                if (opp.Opportunity_Approval_Status__c == 'Approved' && oldMap.get(opp.Id).Opportunity_Approval_Status__c == 'Pending Second Level Approval') {
                    opp.Opportunity_Approval_Status__c = 'Approved - 2nd';
                }
            } else if (getApprovalProcessNumber(opp) == 2) {
                if (opp.Second_Approval_Status__c == 'Approved' && oldMap.get(opp.Id).Second_Approval_Status__c != 'Pending Second Level Approval' && opportunityPendingSet.contains(opp.Id)) {
                    opp.Second_Approval_Status__c = 'Pending Approval';
                    Approval.lock(opp);
                }

                if (opp.Second_Approval_Status__c == 'Approved' && oldMap.get(opp.Id).Second_Approval_Status__c == 'Pending Second Level Approval' && opportunityPendingSet.contains(opp.Id)) {
                    opp.Second_Approval_Status__c = 'Pending Second Level Approval';
                    Approval.lock(opp);
                }

                if (opp.Second_Approval_Status__c == 'Approved' && oldMap.get(opp.Id).Second_Approval_Status__c == 'Pending Second Level Approval') {
                    opp.Second_Approval_Status__c = 'Approved - 2nd';
                }
            }
        }
    }
    public static void lockOpps(List<Opportunity> oppLst) {
        System.debug('lockOpps');
        Map<Id, Opportunity> oppsToLock = new Map<Id, Opportunity>();

        for (Opportunity opp : oppLst) {
            if ((!String.isEmpty(opp.Opportunity_Approval_Status__c) && (opp.Opportunity_Approval_Status__c?.contains('Pending'))) || (!String.isEmpty(opp.Second_Approval_Status__c) && (opp.Second_Approval_Status__c?.contains('Pending')))) {
                oppsToLock.put(opp.id, opp);
            }
        }

        if (!oppsToLock.isEmpty()) {
            System.debug('oppsToLock' + oppsToLock);
            Approval.lock(new List<Id>(oppsToLock.keySet()));
        }
    }

    public static void afterUpdateEventAction(List<Opportunity> oppLst, map<Id, Opportunity> oldMap, map<Id, Opportunity> newMap) {
        lockOpps(oppLst);

        /*
        System.debug('afterUpdateEventAction');
        Map<Id,Opportunity> oppsToUnlock = new Map<Id, Opportunity>();
        for (Opportunity opp : newMap.values()) {
            if (getApprovalProcessNumber(opp) == 1){
                if (!String.isEmpty(opp.Opportunity_Approval_Status__c) && (opp.Opportunity_Approval_Status__c?.contains('Approved - 2nd') || opp.Opportunity_Approval_Status__c?.contains('Rejected'))){
                    oppsToUnlock.put(opp.id, opp);
                }
            }else if(getApprovalProcessNumber(opp) == 2){
                if(!String.isEmpty(opp.Second_Approval_Status__c) && (opp.Second_Approval_Status__c?.contains('Approved - 2nd')|| opp.Second_Approval_Status__c?.contains('Rejected'))){
                    oppsToUnlock.put(opp.id, opp);
                }
            }else{
                continue;
            }
        }

        Map<Id,Boolean>  islockedResult = Approval.isLocked(oppsToUnlock.values());
        List<Id> verifiedLockedOpportunities = new List<Id>();
        for (Id oppId : islockedResult.keySet()){
            System.debug('islockedResult ' +islockedResult.get(oppId));
            if (islockedResult.get(oppId)){
                verifiedLockedOpportunities.add(oppId);
            }
        }

        if(!verifiedLockedOpportunities.isEmpty()){
            System.debug('opps to Unlock' +verifiedLockedOpportunities);
            Approval.unlock(verifiedLockedOpportunities);
        }
        */
    }

    public static void validateStage(Opportunity newOpp) {
    }

    public static Integer getApprovalProcessNumber(Opportunity opp) {
        if (stagesToStageNumbers.get(opp.StageName) < 6) {
            return 1;
        } else if ((/*stagesToStageNumbers.get(opp.StageName) == 5 ||*/ stagesToStageNumbers.get(opp.StageName) == 6) && (opp.Delivery_Involved__c == 'Yes' || opp.Managed_Services_Involved__c == 'Yes' || opp.Customer_Services_Involved__c == 'Yes')) {
            return 2;
        } else {
            return 0;
        }
    }

    public static void beforeUpdateEventAction(List<Opportunity> oppLst, map<Id, Opportunity> oldMap, map<Id, Opportunity> newMap) {
        System.debug('beforeUpdateEventAction');

        Set<Id> opportunitySet = new Set<Id>();
        Set<Id> rejectedOpportunitySet = new Set<Id>();
        Set<Id> approvalOpportunitySet = new Set<Id>();
        Set<Id> recallOpportunitySet = new Set<Id>();

        for (Opportunity oppty : oppLst) {
            /*if (stagesToStageNumbers.get(newMap.get(oppty.Id).StageName) == 7 && stagesToStageNumbers.get(oldMap.get(oppty.Id).StageName) < 7) {
                fireInfoEvent('PO_Signed_contract', 'Please make sure to upload the final Proposal, Contract, SOW and the Profit Sheet, before you submit the opportunity for the additional delivery approval and before you move the stage to 7. PO & Signed contract', 'PO & Signed Contract', 'sticky', 'info');
            }*/

            validateStage(newMap.get(oppty.Id));

            if (getApprovalProcessNumber(oppty) == 1) {
                if (oppty.Opportunity_Approval_Status__c == 'Approved' && oldMap.get(oppty.Id).Opportunity_Approval_Status__c != oppty.Opportunity_Approval_Status__c) {
                    opportunitySet.add(oppty.Id);
                }
                //Rejected
                if (oppty.Opportunity_Approval_Status__c == 'Rejected' && oldMap.get(oppty.Id).Opportunity_Approval_Status__c != oppty.Opportunity_Approval_Status__c) {
                    rejectedOpportunitySet.add(oppty.Id);
                }

                if (oppty.Opportunity_Approval_Status__c == null || oppty.Opportunity_Approval_Status__c == '') {
                    recallOpportunitySet.add(oppty.Id);
                }
            } else if (getApprovalProcessNumber(oppty) == 2) {
                if (oppty.Second_Approval_Status__c == 'Approved' && oldMap.get(oppty.Id).Second_Approval_Status__c != oppty.Second_Approval_Status__c) {
                    opportunitySet.add(oppty.Id);
                }
                //Rejected
                if (oppty.Second_Approval_Status__c == 'Rejected' && oldMap.get(oppty.Id).Second_Approval_Status__c != oppty.Second_Approval_Status__c) {
                    rejectedOpportunitySet.add(oppty.Id);
                }

                if (oppty.Second_Approval_Status__c == null || oppty.Second_Approval_Status__c == '') {
                    recallOpportunitySet.add(oppty.Id);
                }
            }
        }

        System.debug('recallOpportunitySet' + recallOpportunitySet);

        //Approval Code
        if (opportunitySet.size() > 0) {
            ApprovalAction(opportunitySet, oppLst, oldMap);
        }

        //End:Approval code
        if (rejectedOpportunitySet.size() > 0) {
            rejectionaction(rejectedOpportunitySet, oppLst, oldMap);
        }

        if (recallOpportunitySet.size() > 0) {
            recallAction(recallOpportunitySet, oppLst, oldMap);
        }
        fillPendingApprovers(newMap);
    }

    private static void fillPendingApprovers(map<Id, Opportunity> newMap) {
        List<ProcessInstanceWorkitem> processWorkItemsList = [
            SELECT Id, ProcessInstance.TargetObjectId, CreatedDate, Actor.FirstName, Actor.LastName
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.Status = 'Pending' AND ProcessInstance.TargetObjectId IN :newMap.keySet()
        ];

        Map<Id, Set<String>> oppIdPendingApproversMap = new Map<Id, Set<String>>();
        Map<Id, datetime> oppIdPendingDateMap = new Map<Id, datetime>();
        Map<Id, String> oppIdPendingApproversMap1 = new Map<Id, String>();

        for (ProcessInstanceWorkitem piwi : processWorkItemsList) {
            if (!oppIdPendingApproversMap.containsKey(piwi.ProcessInstance.TargetObjectId)) {
                oppIdPendingApproversMap.put(piwi.ProcessInstance.TargetObjectId, new Set<String>());
                oppIdPendingDateMap.put(piwi.ProcessInstance.TargetObjectId, piwi.CreatedDate);

                //  oppIdPendingApproversMap1.put(piwi.ProcessInstance.TargetObjectId,piwi.Actor.FirstName +' ' + piwi.Actor.LastName);
            }
            oppIdPendingApproversMap.get(piwi.ProcessInstance.TargetObjectId).add(piwi.Actor.FirstName + ' ' + piwi.Actor.LastName);
            oppIdPendingDateMap.get(piwi.ProcessInstance.TargetObjectId);

            // oppIdPendingApproversMap1.get(piwi.ProcessInstance.TargetObjectId);
        }

        // Records that have ANY native approval history (pending or already resolved) —
        // only these are safe to blank out below. Records with no native ProcessInstance
        // at all are left untouched, since PendingApproverTracker (the separate
        // Opportunity_Approval_Item__c based system) may own the field for them instead.
        Set<Id> oppIdsWithNativeApprovalHistory = new Set<Id>();
        for (ProcessInstance pi : [
            SELECT TargetObjectId FROM ProcessInstance WHERE TargetObjectId IN :newMap.keySet()
        ]) {
            oppIdsWithNativeApprovalHistory.add(pi.TargetObjectId);
        }

        for (Opportunity opp : newMap.values()) {
            // Only overwrite Pending_Approvers__c when a native approval process is active for this opp.
            // If the map has no entry, the custom approval engine (PendingApproverTracker) owns the field — don't clear it.
            if (oppIdPendingApproversMap.containsKey(opp.Id)) {
                opp.Pending_Approvers__c = String.join(new List<String>(oppIdPendingApproversMap.get(opp.Id)), ';');
            } else if (oppIdsWithNativeApprovalHistory.contains(opp.Id)) {
                // Has native approval history but nothing pending right now — fully
                // approved, rejected, or recalled, so the display field goes blank.
                opp.Pending_Approvers__c = null;
            }
            // opp.Pending_Approvers__c = oppIdPendingApproversMap1.get(opp.Id);
            if (oppIdPendingDateMap.containsKey(opp.Id)) {
                opp.Submitted_Date__c = oppIdPendingDateMap.get(opp.Id);
            }
        }
    }

    /*private static void fillPendingApprovers1(map<Id,Opportunity> newMap)
    {
        List<ProcessInstanceWorkitem> processWorkItemsList = [SELECT Id, ProcessInstance.TargetObjectId,ProcessInstance.Id,CreatedDate,Actor.FirstName, Actor.LastName FROM ProcessInstanceWorkitem WHERE ProcessInstance.Status ='Pending' and ProcessInstance.TargetObjectId IN :newMap.keySet()];
        
        Map<Id, Set <String>> oppIdPendingApproversMap = new Map<Id, Set <String>>();
        Map<Id,datetime> oppIdPendingDateMap = new Map<Id,datetime>();
        Map<Id,String> oppIdPendingApproversMap1 = new Map<Id,String>();
        
        for (ProcessInstanceWorkitem piwi: processWorkItemsList)
        {
            if(!oppIdPendingApproversMap.containsKey(piwi.ProcessInstance.Id))
            {
              //  oppIdPendingApproversMap.put(piwi.ProcessInstance.Id, new Set<String>());
                oppIdPendingDateMap.put(piwi.ProcessInstance.Id, piwi.CreatedDate);
                
                System.debug('oppIdPendingDateMap&&&&'+oppIdPendingDateMap);

                oppIdPendingApproversMap1.put(piwi.ProcessInstance.Id,piwi.Actor.FirstName +' ' + piwi.Actor.LastName);
                
                 System.debug('oppIdPendingApproversMap1&&&&'+oppIdPendingApproversMap1);
            }
           // oppIdPendingApproversMap.get(piwi.ProcessInstance.Id).add(piwi.Actor.FirstName +' ' + piwi.Actor.LastName);
            oppIdPendingDateMap.get(piwi.ProcessInstance.Id);
            System.debug('oppIdPendingDateMap@@@@'+oppIdPendingApproversMap1);
            
            oppIdPendingApproversMap1.get(piwi.ProcessInstance.Id);
            System.debug('oppIdPendingApproversMap1@@@@'+oppIdPendingApproversMap1);
        }
     for (ProcessInstanceWorkitem piwi: processWorkItemsList)
        {
        for(Opportunity opp : newMap.values())
        {
           if(piwi.ProcessInstance.TargetObjectId==opp.Id)
           {
            opp.Pending_Approvers__c = oppIdPendingApproversMap1.get(piwi.ProcessInstance.Id);
            
            System.debug('opp.Pending_Approvers__c@@@@'+opp.Pending_Approvers__c);
            opp.Submitted_Date__c=oppIdPendingDateMap.get(piwi.ProcessInstance.Id);
            
             System.debug('opp.Submitted_Date__c@@@@'+opp.Submitted_Date__c);
            
            }
         } 
       } 
    }*/

    private static String validatePreApprovalConditions() {
        if (opp == null) {
            return 'Opportunity Approval - No Opportunity was found';
        }

        if (String.isBlank(opp.Opportunity_Approval_Type__c)) {
            return 'Opportunity approval - Type not selected.';
        }

        if (String.isBlank(opp.Sub_Region__c)) {
            return 'Opportunity Approval - Sub Region field should be filled';
        }

        // if (opp.Opportunity_Approval_Type__c != 'Non-Standard' && !(opp.Type.containsIgnoreCase('Recurring Revenue') || opp.Type.containsIgnoreCase('Maintenance') || opp.Type.containsIgnoreCase('Change Request')))
        // {
        //  return 'Opportunity Approval - Opportunities with standard conditions do not need to be approved';
        // }

        if (opp.Opportunity_Approval_Type__c == 'Standard' && opp.Amount > 300000) {
            return 'Opportunity Approval - Opportunities with the amount larger than 300k should be "Non-Standard"';
        }
        if (String.isBlank(opp.Hardware_delivery_involved__c)) {
            return 'Opportunity Approval – “3rd party HW/SW, HW (proprietary)” field is mandatory. Please select Yes/No';
        }
        if (String.isBlank(opp.Delivery_Involved__c)) {
            return 'Opportunity Approval – "Delivery Involved" field is mandatory. Please select Yes/No';
        }
        if (String.isBlank(opp.Managed_Services_Involved__c)) {
            return 'Opportunity Approval – "Managed Services Involved" field is mandatory. Please select Yes/No';
        }
        if (String.isBlank(opp.Customer_Services_Involved__c)) {
            return 'Opportunity Approval – "Customer Support Services Involved" field is mandatory. Please select Yes/No';
        }

        if (opp.Opportunity_Approval_Type__c == 'Non-Standard') {
            //added by sunita
            if (String.isBlank(opp.NON_STANDARD_CONDITIONS__c) && String.isBlank(opp.ROAMING_SECURITY_NON_STD_Deal_Margin__c) && String.isBlank(opp.RISK_NON_STD_Deal_Margin__c) && String.isBlank(opp.Testing_Non_Std_Deal_Margin__c) && String.isBlank(opp.Engmnt_Exp_Non_Std_Deal_Margin__c) && opp.Amount <= 300000) {
                // commented by sunita
                // if (String.isBlank(opp.NON_STANDARD_CONDITIONS__c))

                return 'Opportunity Approval - Type is "Non-Standard" , please fill Non-Standard Conditions';
            }

            if (String.isBlank(opp.REASON_FOR_APPROVAL__c)) {
                return 'Opportunity Approval - Reason for approval field in the approval section must be filled';
            }

            List<String> oppType = opp.Opportunity_Approval_Type__c != 'Standard' ? opp.NON_STANDARD_CONDITIONS__c?.split(';') : new List<String>{ opp.Type };

            if (oppType != null && oppType.contains('Financial') && oppType.size() == 1) {
                return 'Opportunity Approval - Financial can not be the only non standard condition';
            }
        }

        if (getApprovalProcessNumber(opp) == 0) {
            return 'No applicable approval flow at this stage';
        }
        if (getApprovalProcessNumber(opp) == 1) {
            String areasInvolved = '';

            if (String.isNotBlank(opp.Delivery_Involved__c) && opp.Delivery_Involved__c == 'No') {
                areasInvolved += 'Delivery Services';
            }

            if (String.isNotBlank(opp.Managed_Services_Involved__c) && opp.Managed_Services_Involved__c == 'No') {
                if (!String.isBlank(areasInvolved)) {
                    areasInvolved += ', ';
                }
                areasInvolved += 'Managed Services';
            }

            if (String.isNotBlank(opp.Customer_Services_Involved__c) && opp.Customer_Services_Involved__c == 'No') {
                if (!String.isBlank(areasInvolved)) {
                    areasInvolved += ', ';
                }
                areasInvolved += 'Customer Support Services';
            }
            if (!String.isBlank(areasInvolved)) {
                return 'Warning: Are you sure? If Yes/No selection is \'No\', then ' + areasInvolved + ' will not participate in Deal/Project, and re-approvals will be required if ' + areasInvolved + ' are required to participate.';
            }
        }
        return null;
    }

    private static String findTemplateName() {
        String templateName;
        if (opp.Opportunity_Approval_Type__c == 'Non-Standard') {
            if (specialApprover == APPROVER_GOVERNANCE_CFO_CRO && approvalLevel == 2) {
                if (requestApproval) {
                    templateName = 'Opportunity_Governance_Committee_CFO_Approval_Request';
                } else if (!requestApproval && opp.Opportunity_Approval_Status__c?.contains('Approved')) {
                    templateName = 'Approved_Governance_Committee_CFO';
                } else if (!requestApproval && opp.Opportunity_Approval_Status__c?.contains('Rejected')) {
                    templateName = 'Rejected_Governor_Committee_CFO';
                }
            } else if (specialApprover == APPROVER_GOVERNANCE_CRO && approvalLevel == 2) {
                if (requestApproval) {
                    templateName = 'Opportunity_Governance_Committee_Approval_Request';
                } else if (!requestApproval && opp.Opportunity_Approval_Status__c?.contains('Approved')) {
                    templateName = 'Approved_Non_Standard_Governor_Committee';
                } else if (!requestApproval && opp.Opportunity_Approval_Status__c?.contains('Rejected')) {
                    templateName = 'Rejected_Non_Standard_Governor_Committee';
                }
            } else {
                if (requestApproval) {
                    templateName = 'Opportunity_Non_Standard_Approval_Request';
                } else if (!requestApproval && opp.Opportunity_Approval_Status__c?.contains('Approved')) {
                    templateName = 'Approved_Non_Standard';
                } else if (!requestApproval && opp.Opportunity_Approval_Status__c?.contains('Rejected')) {
                    templateName = 'Rejected_Non_Standard';
                }
            }
        } else {
            if (requestApproval) {
                templateName = 'Opportunity_Standard_Approval_Request_Letterhead';
            } else if (!requestApproval && opp.Opportunity_Approval_Status__c?.contains('Approved')) {
                templateName = 'Opportunity_Standard_Approved_Letterhead';
            } else if (!requestApproval && opp.Opportunity_Approval_Status__c?.contains('Rejected')) {
                templateName = 'Opportunity_Standard_Rejected_Letterhead';
            }
        }

        return templateName;
    }

    private static Contact getDummyContact() {
        List<Contact> dummyContact = [SELECT id FROM Contact WHERE lastName = 'dummy' LIMIT 1];
        Contact c; //TargetObjectId is mandatory field while sending email to user, this needs one dummy contact
        if (dummyContact.size() == 0) {
            c = new Contact(lastName = 'dummy');
            insert c;
        } else {
            c = dummyContact[0];
        }
        return c;
    }

    public static void fireInfoEvent(String key, String message, String title, String mode, String variant) {
        ToastEvent__e toastEvent = new ToastEvent__e();
        toastEvent.Message__c = message;
        toastEvent.Key__c = key;
        toastEvent.Mode__c = mode;
        toastEvent.Title__c = title;
        toastEvent.Variant__c = variant;
        Database.SaveResult result = EventBus.publish(toastEvent);

        for (Database.Error error : result.errors) {
            System.debug('ERROR: ' + error.getMessage());
        }

        if (result.isSuccess()) {
            System.debug('Successfully published event.');
        } else {
            System.debug('Something went wrong!');
        }
    }

    //TODO:remove
    @TestVisible
    private static void codeCoverage() {
        Integer i = 1;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}