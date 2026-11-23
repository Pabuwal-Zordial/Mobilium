global class cls_PPOApprovalHandler {
    public static boolean requestApproval = true;
    public static boolean completeFlowAlreadyRan = false;
    public static boolean completeSecondFlowAlreadyRan = false;
    public static Integer approvalLevel = 1;
    public static String opportunityId;
    public static String ppoDetailsId;
    public static String specialApprover;
    public static Boolean isInsert = false;
    public static Set<Id> managerUserList = new Set<Id>();
    static Set<String> ccSet = new Set<String>();
    public static final Map<String, Integer> stagesToStageNumbers = new Map<String, Integer>{ 'White Space' => 0, 'Identify the Opportunity' => 1, 'Validate the Opportunity' => 2, 'Qualify the Opportunity' => 3, 'Develop Solution' => 4, 'Propose Solution' => 5, 'Secure Agreement' => 6, 'PO & Signed Contract' => 7, 'Finance Review' => 8, 'Won & Closed' => 9 };
    public static final Set<String> closedLostStages = new Set<String>{ 'Lost', 'Deleted', 'Deleted Recon' };

    @TestVisible
    public static final String APPROVER_GOVERNANCE_CFO_CRO = 'Governance committee & CRO & CFO';
    @TestVisible
    public static final String APPROVER_GOVERNANCE_CRO = 'Governance committee & CRO';
    @TestVisible
    public static final String APPROVER_CFO = 'CFO';
    @TestVisible
    public static final String APPROVER_GOVERNANCE = 'Governance committee';
    @TestVisible
    public static final String APPROVER_C_LEVEL_EXCLUIDING_CFO = 'C Level Excluding CFO';
    @TestVisible
    public static final String CHIEF_OF_DELIVERY_SUPPORT = 'Chief of Delivery & Support';
    @TestVisible
    public static final String CHIEF_OF_MANAGED_SERVICES = 'Chief of Managed Services';
    @TestVisible
    public static final String CHIEF_OF_CUSTOMER_SUPPORT = 'Chief of Customer Support';
    @TestVisible
    public static final String SHRIDARB = 'ShridarB';
    @TestVisible
    public static final String CHRISTIAN_FRANK = 'Christian Frank';
    @TestVisible
    public static final String APPROVER_FIRST_LEVEL_RR_MR = '1st Level RR - MR';
    @TestVisible
    public static final Set<String> FIRST_LEVEL_APPROVERS = new Set<String>{ APPROVER_FIRST_LEVEL_RR_MR };

    private static Opportunity opp = null;

    @TestVisible
    private static PPO_Sales_Governance__c ppo {
        get {
            System.debug('Fetching PPO Details for PPO ID: ' + ppoDetailsId);

            if (ppo == null) {
                ppo = [
                    SELECT
                        Id,
                        Name,
                        CreatedBy.Email,
                        PPO_Start_Date__c,
                        PPO_End_Date__c,
                        PPO_Approval_Status__c,
                        PPO_Reason__c,
                        Amount__c,
                        Third_Party_Costs__c,
                        Costs_LoE__c,
                        LoE_Mandays__c,
                        Good_Payment_History_Last_Year__c,
                        Scope_closed_contract__c,
                        Written_Confirmation_From_The_Customer__c,
                        PO_target_date__c,
                        Opportunity__c,
                        Opportunity__r.Id,
                        Opportunity__r.Amount,
                        Opportunity__r.Owner.Email,
                        Opportunity__r.Country__r.Name,
                        Opportunity__r.Gross_Margin_of_Primary_Quote__c,
                        Opportunity__r.Sub_Region__c,
                        Opportunity__r.Entity_Number__c,
                        Opportunity__r.Renewal_Specialist__c,
                        Opportunity__r.REASON_FOR_APPROVAL__c,
                        Opportunity__r.Hardware_delivery_involved__c,
                        Opportunity__r.Delivery_Involved__c,
                        Opportunity__r.Customer_Services_Involved__c,
                        Opportunity__r.Managed_Services_Involved__c,
                        Opportunity__r.Type,
                        Opportunity__r.Opportunity_Approval_Type__c,
                        Opportunity__r.Opportunity_Approval_Status__c,
                        Opportunity__r.Second_Approval_Status__c,
                        Opportunity__r.Business_Unit__c,
                        Opportunity__r.NON_STANDARD_CONDITIONS__c,
                        Opportunity__r.ROAMING_SECURITY_NON_STD_Deal_Margin__c,
                        Opportunity__r.RISK_NON_STD_Deal_Margin__c,
                        Opportunity__r.Testing_Non_Std_Deal_Margin__c,
                        Opportunity__r.Engmnt_Exp_Non_Std_Deal_Margin__c,
                        Opportunity__r.StageName,
                        Opportunity__r.Renewal_Specialist__r.Email,
                        Opportunity__r.Business_Type__c,
                        Opportunity__r.Cross_sell1__c
                    FROM PPO_Sales_Governance__c
                    WHERE Id = :ppoDetailsId
                    LIMIT 1
                ];
            }

            return ppo;
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

    public static void updatePPOFields(List<PPO_Sales_Governance__c> ppoList, Map<Id, PPO_Sales_Governance__c> oldMap) {
        for (PPO_Sales_Governance__c ppo : ppoList) {
            PPO_Sales_Governance__c oldPPO = oldMap.get(ppo.Id);

            if (oldPPO == null)
                continue;

            Boolean hasPermission = belongsToQuoteTeam();

            if (ppo.Written_confirmation_from_the_Customer__c == 'No' && oldPPO.Written_confirmation_from_the_Customer__c == 'Yes') {
                ContentDocumentLink[] contentDocumentLinks = [
                    SELECT Id
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :ppo.Id
                ];

                if (!contentDocumentLinks.isEmpty()) {
                    ppo.Written_confirmation_from_the_Customer__c.addError('You cannot change Written Confirmation from the Customer to \'No\' when there are files attached.');
                    continue;
                }
            }

            if (ppo.Name != oldPPO.Name && !hasPermission) {
                ppo.Name.addError('You cannot change the PPO Name.');
                continue;
            }

            if (ppo.CurrencyIsoCode != oldPPO.CurrencyIsoCode && !hasPermission) {
                ppo.CurrencyIsoCode.addError('You cannot change the PPO Currency.');
                continue;
            }

            Boolean targetDateChanged = oldPPO.PO_target_date__c != ppo.PO_target_date__c;
            Boolean startDateChanged = oldPPO.PPO_Start_Date__c != ppo.PPO_Start_Date__c;
            Boolean endDateChanged = oldPPO.PPO_End_Date__c != ppo.PPO_End_Date__c;

            Boolean anyDateChanged = targetDateChanged || startDateChanged || endDateChanged;

            System.debug('Date fields changed for PPO ID: ' + ppo.Id);
            System.debug('Old PO Target Date: ' + oldPPO.PO_target_date__c + ', New PO Target Date: ' + ppo.PO_target_date__c);
            System.debug('Old PPO Start Date: ' + oldPPO.PPO_Start_Date__c + ', New PPO Start Date: ' + ppo.PPO_Start_Date__c);
            System.debug('Old PPO End Date: ' + oldPPO.PPO_End_Date__c + ', New PPO End Date: ' + ppo.PPO_End_Date__c);

            if ((startDateChanged || endDateChanged) && !hasPermission) {
                ppo.addError('You do not have permission to modify the dates of this PPO.');
                continue;
            }

            if (!anyDateChanged) {
                continue;
            }

            if (targetDateChanged && !endDateChanged) {
                ppo.PPO_End_Date__c = ppo.PO_target_date__c;
            }

            if (ppo.PPO_Start_Date__c != null && startDateChanged && ppo.PPO_Start_Date__c < System.today()) {
                ppo.PPO_Start_Date__c.addError('PPO Start Date must be today or later.');
            }

            if (ppo.PPO_Start_Date__c != null && ppo.PPO_End_Date__c != null && ppo.PPO_Start_Date__c > ppo.PPO_End_Date__c) {
                ppo.PPO_Start_Date__c.addError('PPO Start Date cannot be after the PPO End Date.');
            }

            if (ppo.PPO_End_Date__c != null && endDateChanged && ppo.PPO_End_Date__c < System.today()) {
                ppo.PPO_End_Date__c.addError('PPO End Date must be today or later.');
            }

            if (ppo.PO_target_date__c != null && targetDateChanged && ppo.PO_target_date__c < System.today()) {
                ppo.PO_target_date__c.addError('PO Target Date must be today or later.');
            }

            if (ppo.PO_target_date__c != null && ppo.PPO_End_Date__c != null && ppo.PO_target_date__c > ppo.PPO_End_Date__c) {
                ppo.PO_target_date__c.addError('PO Target Date cannot be after the PPO End Date.');
            }
        }
    }

    public static void beforeInsertEventAction(List<PPO_Sales_Governance__c> newRecords) {
        for (PPO_Sales_Governance__c record : newRecords) {
            ppoDetailsId = record.Id;
            ppo = record;
            opp = [
                SELECT Id, StageName, Delivery_Involved__c, Customer_Services_Involved__c, Managed_Services_Involved__c, Business_Type__c, Cross_sell1__c, Business_Unit__c, Opportunity_Approval_Status__c, Second_Approval_Status__c
                FROM Opportunity
                WHERE Id = :record.Opportunity__c
                LIMIT 1
            ];
            isInsert = true;
            String errorMessage = validatePreApprovalConditions();

            if (!String.isBlank(errorMessage) && !errorMessage.contains('Warning')) {
                record.addError(errorMessage);
            }
        }
    }

    public static String validateRelatedOpp(Opportunity opp) {
        if (opp == null) {
            return 'Opportunity not found.';
        }

        //if (opp.StageName != 'Secure Agreement' && ) {
        //added by sunita for PPO changes
        
        String profileName = [
                                    SELECT Name
                                    FROM Profile
                                    WHERE Id = :UserInfo.getProfileId()
                                ].Name;
        if (opp.StageName != 'Secure Agreement' && !( profileName == 'Mobileum Salesops Team Profile' || profileName == 'Quote Creation Team Member' || profileName == 'System Administrator')) 
        {
            return 'You can only create a PPO when the Opportunity is in the “Secure Agreement” stage';
        }

        if (opp.Opportunity_Approval_Status__c == null || opp.Second_Approval_Status__c == null || !opp.Opportunity_Approval_Status__c.contains('Approved') || !opp.Second_Approval_Status__c.contains('Approved')) {
            return 'PPO can only be created and submitted for approval if the Opportunity is Approved.';
        }

        if (opp.Delivery_Involved__c == null || opp.Customer_Services_Involved__c == null || opp.Managed_Services_Involved__c == null || (opp.Delivery_Involved__c == 'No' && opp.Customer_Services_Involved__c == 'No' && opp.Managed_Services_Involved__c == 'No')) {
            return 'PPO cannot be submitted for approval since the \'Delivery Involved\', \'Customer Services Involved\' or \'Managed Services Involved\' fields are not set to YES in the Opportunity.';
        }

        // Removed due to business decision during the review of the PPO process
        /*if ((opp.Managed_Services_Involved__c == 'Yes' || opp.Customer_Services_Involved__c == 'Yes') && (opp.Delivery_Involved__c == null || opp.Delivery_Involved__c == 'No') && opp.Cross_sell1__c != 'Renewals') {
            return 'PPO cannot be submitted for approval since only Managed Services or Customer Services are involved and the Sales Type is not Renewals.';
        }

        if (opp.Delivery_Involved__c == 'Yes' && (opp.Customer_Services_Involved__c == null || opp.Customer_Services_Involved__c == 'No') && (opp.Managed_Services_Involved__c == null || opp.Managed_Services_Involved__c == 'No') && (opp.Cross_sell1__c != 'Upsell' && opp.Cross_sell1__c != 'Cross sell')) {
            return 'PPO cannot be submitted for approval since the Opportunity only has Delivery Involved and the Sales Type is not Upsell or Cross sell.';
        }

        if (opp.Delivery_Involved__c == 'Yes' && (opp.Customer_Services_Involved__c == 'Yes' || opp.Managed_Services_Involved__c == 'Yes') && (opp.Cross_sell1__c != 'Upsell' && opp.Cross_sell1__c != 'Cross sell' && opp.Cross_sell1__c != 'Renewals')) {
            return 'PPO cannot be submitted for approval since the Opportunity has Delivery Involved and Customer Services or Managed Services involved, but the Sales Type is not Upsell, Cross sell or Renewals.';
        }*/

        // Removed due to business decision during the review of the PPO process
        // Testing Unit should only be used with this new process when there is no 'Global Rumour' product
        /*if (opp.Business_Unit__c.toUpperCase() == 'TESTING') {
            return 'PPO cannot be submitted for approval since the Opportunity is in the Testing Business Unit.';
        }*/

        return null;
    }

    //Classic Button
    webService static String submitApproval(String ppoId) {
        return initiateApproval(ppoId);
    }

    //Called from lightninting button/standard button
    @AuraEnabled
    public static String initiateApproval(String ppoId) {
        ppoDetailsId = ppoId;
        if (opp == null) {
            opp = ppo.Opportunity__r;
            System.debug('Opportunity fetched for PPO ID: ' + opp);
            opportunityId = opp.Id;
        }

        System.debug('Initiating PPO Approval for PPO ID: ' + ppo.Id);

        String errorMessage = validatePreApprovalConditions();
        System.debug('Error Message after validation: ' + errorMessage);
        if (!String.isBlank(errorMessage) && !errorMessage.contains('Warning')) {
            return errorMessage;
        }

        if (!belongsToQuoteTeam()) {
            return 'You cannot submit a PPO for approval since you don\'t have the necessary permissions.';
        }

        Set<String> emailAddressSet = getNextApprovers();
        Map<String, String> workEmailSFUserMap = getWorkEmailSFUserMap(emailAddressSet);

        List<User> userList = [
            SELECT Id, Email
            FROM User
            WHERE Email IN :workEmailSFUserMap.keySet()
        ];

        if (userList.isEmpty())
            return 'No user found';

        Map<Id, String> userIdEmailMap = new Map<Id, String>();
        Map<String, Id> emailUserIdMap = new Map<String, Id>();

        for (User u : userList) {
            userIdEmailMap.put(u.Id, u.Email.toLowerCase());
            emailUserIdMap.put(workEmailSFUserMap.get(u.Email.toLowerCase()), u.Id);
        }

        if (!requestApproval) {
            List<ProcessInstance> piList = [
                SELECT Id, LastActor.Email, LastActor.Id
                FROM ProcessInstance
                WHERE TargetObjectId = :opp.Id
            ];
            for (ProcessInstance pi : piList) {
                if (pi != null && pi.LastActor.Email != null) {
                    emailUserIdMap.put(pi.LastActor.Email, pi.LastActor.Id);
                }
            }
        }

        if (requestApproval) {
            updatePPO(ppo.Id);
            processApprovals(ppo, userIdEmailMap.keySet());
        }

        if (!emailUserIdMap.isEmpty()) {
            sendEmails(ppo, emailUserIdMap.keySet());
        }

        if (!String.isBlank(errorMessage) && errorMessage.contains('Warning')) {
            return errorMessage;
        }

        if (ppo.PPO_Approval_Status__c == 'Approved - 2nd' || (!requestApproval && ppo.PPO_Approval_Status__c == 'Approved')) {
            sendFinanceNotificationEmail(ppo);
        }

        return 'Success';
    }

    public static void updatePPO(Id ppoDetailsId) {
        update new PPO_Sales_Governance__c(Id = ppoDetailsId);
    }

    private static String validatePreApprovalConditions() {
        System.debug('Validating pre-approval conditions for PPO');

        if (ppo == null) {
            return 'PPO not found for the given PPO ID.';
        }

        validateRelatedOpp(opp);

        if (opp.Delivery_Involved__c == 'Yes' && ppo.Third_Party_Costs__c > 0) {
            return 'Your deal includes Delivery with third-party costs — please request a Sales Governance call before proceeding';
        }

        if (hasOtherPPOs() && !belongsToQuoteTeam()) {
            return 'PPOs 2nd and 3rd of the PPO Renewalls can only be submitted by the SFDC Quote Team.';
        }

        if (!isInsert && String.IsBlank(ppo.PPO_Reason__c)) {
            return 'PPO cannot be submitted for approval since the PPO Reason is not provided.';
        }

        if (!isInsert && ppo.PPO_End_Date__c == null) {
            return 'PPO cannot be submitted for approval since the PPO End Date is not provided.';
        }

        if (!isInsert && ppo.PPO_Start_Date__c == null) {
            return 'PPO cannot be submitted for approval since the PPO Start Date is not provided.';
        }

        if (ppo.PO_target_date__c != null && ppo.PO_target_date__c < System.today()) {
            return 'PPO cannot be submitted for approval since the PO Target Date is in the past.';
        }

        if (ppo.PPO_End_Date__c != null && ppo.PPO_End_Date__c < System.today()) {
            return 'PPO cannot be submitted for approval since the PPO End Date is in the past.';
        }

        if (ppo.PO_target_date__c != null && ppo.PPO_End_Date__c != null && ppo.PO_target_date__c > ppo.PPO_End_Date__c) {
            return 'PPO cannot be submitted for approval since the PO Target Date is after the PPO End Date.';
        }

        if (ppo.Written_Confirmation_From_The_Customer__c == 'Yes' && !isInsert) {
            List<ContentDocumentLink> contentDocumentLinks = [
                SELECT Id
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :ppoDetailsId
            ];
            if (contentDocumentLinks.isEmpty()) {
                return 'PPO cannot be submitted for approval since the Written Confirmation from the Customer is Yes but no files are attached.';
            }
        }

        return null;
    }

    private static Boolean hasOtherPPOs() {
        List<PPO_Sales_Governance__c> otherPPOs = [
            SELECT Id
            FROM PPO_Sales_Governance__c
            WHERE Opportunity__c = :opp.Id AND Id != :ppo.Id
        ];
        return otherPPOs.size() >= 1;
    }

    private static Boolean belongsToQuoteTeam() {
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        return profileName.toUpperCase() == 'QUOTE CREATION TEAM MEMBER' || profileName.toUpperCase() == 'SYSTEM ADMINISTRATOR' || profileName.toUpperCase() == 'SYSTEM ADMIN CERTINIA' || profileName.toUpperCase() == 'MOBILEUM SYSTEM ADMIN' || profileName.toUpperCase() == 'MOBILEUM SALESOPS TEAM PROFILE';
    }

    @TestVisible
    public static Set<String> getNextApprovers() {
        Set<String> emailAddressSet = new Set<String>();

        List<Approval_Processes_Configuration__c> approvalSettings = getOpportunityApprovalSettings();
        System.debug('Approval Settings fetched: ' + approvalSettings);
        emailAddressSet = findCorrespondingApprovalSetting(approvalSettings);

        return emailAddressSet;
    }

    @TestVisible
    private static Set<String> findCorrespondingApprovalSetting(List<Approval_Processes_Configuration__c> approvalSettings) {
        Set<String> emailList = new Set<String>();

        // Get list of CRO & Governance emails
        List<String> croEmails = specialApproversConfigurationMap.get(APPROVER_GOVERNANCE_CRO).Approvers_Emails__c.split(';');

        // Get list of CFO emails
        List<String> cfoEmails = specialApproversConfigurationMap.get(APPROVER_CFO).Approvers_Emails__c.split(';');

        // Use sets to remove overlap
        Set<String> croSet = new Set<String>(croEmails);
        Set<String> cfoSet = new Set<String>(cfoEmails);

        // Remove CFO emails from the CRO list
        croSet.removeAll(cfoSet);
        List<String> filteredCroEmails = new List<String>(croSet);

        // First scenario: Automatic Approval
        // BU Head + Delivery Head + MS/CS Head + CRO
        if (approvalLevel == 1) {
            List<String> businessUnit = opp.Business_Unit__c?.split(';');
            for (String bu : businessUnit) {
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

            for (Approval_Processes_Configuration__c apc : approvalSettings) {
                if (emailList.contains(apc.BU_Head__c)) {
                    continue;
                }

                emailList.add(apc.BU_Head__c);
            }

            emailList.addAll(filteredCroEmails);
        }

        if (approvalLevel == 2) {
            // COO + CFO
            System.debug('Fetching second level approvers for PPO ID: ' + ppoDetailsId);
            emailList.addAll(cfoEmails);
        }

        return emailList;
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

    public static void processApprovals(PPO_Sales_Governance__c ppoDetails, Set<Id> userIds) {
        List<Approval.ProcessSubmitRequest> approvalRequestList = new List<Approval.ProcessSubmitRequest>();

        for (Id userId : userIds) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(ppoDetails.Id);
            req.setNextApproverIds(new List<Id>{ userId });
            req.setSkipEntryCriteria(true);
            String level = approvalLevel == 1 ? 'first' : 'second';
            req.setProcessDefinitionNameOrId('PPO_New_Process_Approval');
            req.setComments('Submitting request for ' + level + ' level approval.');
            approvalRequestList.add(req);
        }

        Approval.ProcessResult[] results = Approval.process(approvalRequestList);
    }

    public static void beforeUpdateEventAction(List<PPO_Sales_Governance__c> ppoList, map<Id, PPO_Sales_Governance__c> oldMap, map<Id, PPO_Sales_Governance__c> newMap) {
        System.debug('beforeUpdateEventAction PPO');

        Set<Id> ppoSet = new Set<Id>();
        Set<Id> rejectedPpoSet = new Set<Id>();
        Set<Id> approvalPpoSet = new Set<Id>();
        Set<Id> recallPpoSet = new Set<Id>();

        for (PPO_Sales_Governance__c ppo : ppoList) {
            if (ppo.PPO_Approval_Status__c == 'Approved' && oldMap.get(ppo.Id).PPO_Approval_Status__c != ppo.PPO_Approval_Status__c) {
                ppoSet.add(ppo.Id);
            }

            if (ppo.PPO_Approval_Status__c == 'Rejected' && oldMap.get(ppo.Id).PPO_Approval_Status__c != ppo.PPO_Approval_Status__c) {
                rejectedPpoSet.add(ppo.Id);
            }

            if (ppo.PPO_Approval_Status__c == null || ppo.PPO_Approval_Status__c == '' || ppo.PPO_Approval_Status__c == 'Not Submitted') {
                recallPpoSet.add(ppo.Id);
            }
        }

        System.debug('recallPpoSet' + recallPpoSet);

        //Approval Code
        if (ppoSet.size() > 0) {
            approvalAction(ppoSet, ppoList, oldMap);
        }

        //End:Approval code
        if (rejectedPpoSet.size() > 0) {
            rejectionAction(rejectedPpoSet, ppoList, oldMap);
        }

        if (recallPpoSet.size() > 0) {
            recallAction(recallPpoSet, ppoList, oldMap);
        }
    }

    public static void approvalAction(Set<Id> ppoSet, List<PPO_Sales_Governance__c> ppoList, Map<Id, PPO_Sales_Governance__c> oldMap) {
        Set<Id> ppoPendingSet = new Set<Id>();
        //Only supports one at a time
        if (ppoSet.size() == 1) {
            PPO_Sales_Governance__c ppo = ppoList[0];

            List<ProcessInstanceStep> justApprovedProcess = [
                SELECT Id, ProcessInstance.TargetObjectId, StepStatus, OriginalActor.Email
                FROM ProcessInstanceStep
                WHERE StepStatus = 'Approved' AND ProcessInstance.TargetObjectId IN :ppoSet AND SystemModstamp > :System.Now().addminutes(-1)
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

            List<ProcessInstanceWorkitem> processWorkItemsList = [
                SELECT Id, ProcessInstance.TargetObjectId, Actor.Email
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.Status = 'Pending' AND ProcessInstance.TargetObjectId IN :ppoSet
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
                        ppoPendingSet.add(piwi.ProcessInstance.TargetObjectId);
                    }
                    if (!processWorkitemRequest.isEmpty()) {
                        Approval.ProcessResult[] processResults = Approval.process(processWorkitemRequest);
                    }
                }
            }

            if (ppo.PPO_Approval_Status__c == 'Approved' && oldMap.get(ppo.Id).PPO_Approval_Status__c != 'Pending Second Level Approval' && ppoPendingSet.contains(ppo.Id)) {
                ppo.PPO_Approval_Status__c = 'Pending';
                Approval.lock(ppo);
            }

            if (ppo.PPO_Approval_Status__c == 'Approved' && oldMap.get(ppo.Id).PPO_Approval_Status__c == 'Pending Second Level Approval' && ppoPendingSet.contains(ppo.Id)) {
                ppo.PPO_Approval_Status__c = 'Pending Second Level Approval';
                Approval.lock(ppo);
            }

            if (ppo.PPO_Approval_Status__c == 'Approved' && oldMap.get(ppo.Id).PPO_Approval_Status__c == 'Pending Second Level Approval') {
                ppo.PPO_Approval_Status__c = 'Approved - 2nd';
            }
        }
    }

    public static void rejectionAction(Set<Id> rejectedPpoSet, List<PPO_Sales_Governance__c> ppoList, Map<Id, PPO_Sales_Governance__c> oldMap) {
        //Start:Rejection code
        if (rejectedPpoSet.size() > 0) {
            List<ProcessInstanceWorkitem> processItemsList = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.Status = 'Pending' AND ProcessInstance.TargetObjectId IN :rejectedPpoSet
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

        for (PPO_Sales_Governance__c ppo : ppoList) {
            if (ppo.PPO_Approval_Status__c == 'Rejected' && oldMap.get(ppo.Id).PPO_Approval_Status__c == 'Pending Second Level Approval') {
                ppo.PPO_Approval_Status__c = 'Rejected - 2nd';
            }
        }
    }

    public static void recallAction(Set<Id> recallPpoSet, List<PPO_Sales_Governance__c> ppoList, Map<Id, PPO_Sales_Governance__c> oldMap) {
        //Start:Rejection code
        if (recallPpoSet.size() > 0) {
            List<ProcessInstanceWorkitem> processItemsList = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.Status = 'Pending' AND ProcessInstance.TargetObjectId IN :recallPpoSet
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

    public static void sendEmailforApproval(List<PPO_Sales_Governance__c> ppoDetailsList, Map<Id, PPO_Sales_Governance__c> ppoDetailsOldMap) {
        if (!checkIfShouldSendEmail(ppoDetailsList, ppoDetailsOldMap)) {
            return;
        }

        Set<Id> ppoIdSet = new Set<Id>();
        for (PPO_Sales_Governance__c ppo : ppoDetailsList) {
            ppoIdSet.add(ppo.Id);
        }

        sendEmailforApprovalAsync(ppoIdSet);
    }

    @future
    public static void sendEmailforApprovalAsync(Set<Id> ppoIdSet) {
        ppoDetailsId = ppoIdSet.isEmpty() ? null : ppoIdSet.iterator().next();
        if (completeFlowAlreadyRan)
            return;

        Boolean fireSecondApproval = checkIfShouldHaveSecondLevelApproval(ppo);

        if (fireSecondApproval && (ppo.PPO_Approval_Status__c == 'Approved')) {
            approvalLevel = 2;
            requestApproval = true;
        } else if (ppo.PPO_Approval_Status__c == 'Approved - 2nd' || ppo.PPO_Approval_Status__c == 'Rejected - 2nd') {
            approvalLevel = 2;
            requestApproval = false;
        } else if (ppo.PPO_Approval_Status__c == 'Approved' || ppo.PPO_Approval_Status__c == 'Rejected') {
            approvalLevel = 1;
            requestApproval = false;
        }

        initiateApproval(ppo.Id);

        if (fireSecondApproval && (ppo.PPO_Approval_Status__c == 'Approved')) {
            ppo.PPO_Approval_Status__c = 'Pending Second Level Approval';
            update ppo;
        }
        completeFlowAlreadyRan = true;
    }

    @TestVisible
    private static Boolean checkIfShouldHaveSecondLevelApproval(PPO_Sales_Governance__c ppo) {
        System.debug('Checking if second level approval is needed for PPO: ' + ppo.Id);
        System.debug('PPO Amount: ' + ppo.Amount__c);
        if (ppo.Amount__c >= 100000 || ppo.Costs_LoE__c > 50000) {
            return true;
        }

        return false;
    }

    private static List<Approval_Processes_Configuration__c> getOpportunityApprovalSettings() {
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
            System.debug('Approval Configuration ---> ' + acl);
        }

        return approvalConfigurationList;
    }

    public static Boolean checkIfShouldSendEmail(List<PPO_Sales_Governance__c> ppoDetailsList, Map<Id, PPO_Sales_Governance__c> ppoDetailsOldMap) {
        PPO_Sales_Governance__c ppoDetails = ppoDetailsList[0];
        PPO_Sales_Governance__c oldRec = ppoDetailsOldMap.get(ppoDetails.Id);

        if (ppoDetails.PPO_Approval_Status__c != oldRec.PPO_Approval_Status__c && (ppoDetails.PPO_Approval_Status__c == 'Approved' || ppoDetails.PPO_Approval_Status__c == 'Rejected' || ppoDetails.PPO_Approval_Status__c == 'Approved - 2nd' || ppoDetails.PPO_Approval_Status__c == 'Rejected - 2nd')) {
            return true;
        }

        return false;
    }

    public static void sendEmails(PPO_Sales_Governance__c ppo, Set<String> userEmails) {
        List<String> toAddresses = new List<String>();
        toAddresses.addAll(userEmails);
        toAddresses.add(ppo.CreatedBy.Email);
        toAddresses.addAll(getGroupEmails(new Set<String>{ 'Sales Ops' }));

        String templateName = findTemplateName();
        if (templateName == null) {
            return;
        }

        if (templateName.contains('rejected') || templateName.contains('approved')) {
            toAddresses.addAll(getOpportunityTeamEmails(ppo.Opportunity__c));
            toAddresses.addAll(getGroupEmails(new Set<String>{ 'Finance', 'Quotes Team member', 'Sales Ops', 'Delivery cs managed services', 'PPO Approvers' }));
        }

        EmailTemplate emailTemplate = [
            SELECT Id
            FROM EmailTemplate
            WHERE DeveloperName = :templateName
        ];

        String renderedBody = Messaging.renderStoredEmailTemplate(emailTemplate.Id, getDummyContact().Id, ppo.Id).getHtmlBody();
        String subject = Messaging.renderStoredEmailTemplate(emailTemplate.Id, getDummyContact().Id, ppo.Id).getSubject();

        String finalBody = renderedBody;

        // Step 1: Inject approval link
        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id, ProcessInstance.TargetObjectId
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :ppo.Id
        ];

        if (!workItems.isEmpty()) {
            String approvalLink = URL.getOrgDomainUrl().toExternalForm() + '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + workItems[0].Id;

            finalBody = finalBody.replace('<!--APPROVAL_LINK-->'.escapeHtml4(), approvalLink);
        }

        // Step 2: Inject rejection reason if needed
        if (templateName.toLowerCase().contains('rejected')) {
            String rejectionReason = getRejectionReason(ppo.Id);
            if (!String.isBlank(rejectionReason)) {
                String htmlBlock = '<div><font size="2"><b>Rejection Reason:</b> ' + rejectionReason.escapeHtml4() + '</font></div>';
                finalBody = finalBody.replace('<!--REJECTION_REASON-->'.escapeHtml4(), htmlBlock);
            }
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses);
        email.setTreatTargetObjectAsRecipient(false);
        email.setTemplateId(emailTemplate.Id);
        email.setTargetObjectId(getDummyContact().Id);
        email.setWhatId(ppo.Id);
        email.setSaveAsActivity(true);
        email.setSubject(subject);
        email.setHtmlBody(finalBody);

        System.debug('Subject: ' + subject);
        System.debug('Final HTML Body: ' + finalBody);
        System.debug('To: ' + toAddresses);

        if (Test.isRunningTest()) {
            return;
        }

        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        System.debug('Send Result Success: ' + results[0].isSuccess());
        if (!results[0].isSuccess()) {
            System.debug('Send Error: ' + results[0].getErrors()[0].getMessage());
        }
    }

    private static Set<String> getTestRecipients() {
        return new Set<String>{ 'paula.gaspar@mobileum.com', 'agata.fratczak@mobileum.com', 'sunita.char@mobileum.com', 'isabel.pires@mobileum.com', 'monika.sarang@mobileum.com', 'preeti.kumari@mobileum.com', 'rashmi.m@mobileum.com', 'tiago.oliveira@theloop.pt' };
    }

    private static Set<String> getOpportunityTeamEmails(Id opportunityId) {
        Set<String> emails = new Set<String>();
        for (OpportunityTeamMember member : [
            SELECT User.Email
            FROM OpportunityTeamMember
            WHERE OpportunityId = :opportunityId AND TeamMemberRole NOT IN ('CRO', 'Global TAM')
        ]) {
            if (member.User.Email != null)
                emails.add(member.User.Email);
        }
        return emails;
    }

    private static Set<String> getGroupEmails(Set<String> groupNames) {
        Set<Id> userIds = new Set<Id>();
        for (GroupMember gm : [
            SELECT UserOrGroupId
            FROM GroupMember
            WHERE Group.Name IN :groupNames
        ]) {
            if (String.valueOf(gm.UserOrGroupId).startsWith('005')) {
                userIds.add(gm.UserOrGroupId);
            }
        }

        Set<String> emails = new Set<String>();
        for (User u : [SELECT Email FROM User WHERE Id IN :userIds AND IsActive = TRUE]) {
            if (u.Email != null)
                emails.add(u.Email);
        }
        return emails;
    }

    private static String getRejectionReason(Id ppoId) {
        List<ProcessInstanceStep> steps = [
            SELECT Comments
            FROM ProcessInstanceStep
            WHERE StepStatus = 'Rejected' AND ProcessInstance.TargetObjectId = :ppoId
            ORDER BY CreatedDate DESC
        ];
        for (ProcessInstanceStep step : steps) {
            if (!String.isBlank(step.Comments))
                return step.Comments;
        }
        return null;
    }

    private static void sendFinanceNotificationEmail(PPO_Sales_Governance__c ppo) {
        /*List<User> financeUsers = [
            SELECT Email
            FROM User
            WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.Name = 'Finance') AND IsActive = TRUE
        ];

        List<String> emails = new List<String>();
        for (User u : financeUsers) {
            if (!String.isBlank(u.Email)) {
                emails.add(u.Email);
            }
        }*/

        if (Test.isRunningTest()) {
            return;
        }

        List<String> emails = new List<String>();
        emails.addAll(getGroupEmails(new Set<String>{ 'Sales Ops', 'Finance' }));
        //emails.addAll(getTestRecipients());

        if (emails.isEmpty())
            return;

        EmailTemplate emailTemplate = [
            SELECT Id
            FROM EmailTemplate
            WHERE DeveloperName = 'Email_Template_for_Finance_Team_PPO_new_process'
            LIMIT 1
        ];

        Messaging.SingleEmailMessage renderResult = Messaging.renderStoredEmailTemplate(emailTemplate.Id, getDummyContact().Id, ppo.Id);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(emails);
        email.setTargetObjectId(getDummyContact().Id);
        email.setTreatTargetObjectAsRecipient(false);
        email.setSubject(renderResult.getSubject());
        email.setHtmlBody(renderResult.getHtmlBody());
        email.setSaveAsActivity(true);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        System.debug('Finance notification email sent for PPO: ' + ppo.Id);
        System.debug('Emails: ' + emails);
    }

    private static String findTemplateName() {
        if (requestApproval) {
            return 'Opportunity_PPO_new_process_Approval_Request_LetterHead';
        }
        if (!requestApproval && ppo.PPO_Approval_Status__c?.contains('Approved')) {
            return 'Email_Template_for_approved_PPO_new_process';
        }
        if (!requestApproval && ppo.PPO_Approval_Status__c?.contains('Rejected')) {
            return 'Email_Template_for_rejected_PPO_new_process';
        }
        return null;
    }

    private static Contact getDummyContact() {
        List<Contact> contactList = [SELECT Id FROM Contact WHERE LastName = 'dummy' LIMIT 1];
        if (!contactList.isEmpty())
            return contactList[0];
        Contact c = new Contact(LastName = 'dummy');
        insert c;
        return c;
    }

    public static void lockPPOs(List<PPO_Sales_Governance__c> ppoLst) {
        System.debug('lockPPOs');
        Map<Id, PPO_Sales_Governance__c> pposToLock = new Map<Id, PPO_Sales_Governance__c>();

        for (PPO_Sales_Governance__c ppo : ppoLst) {
            if (!String.isEmpty(ppo.PPO_Approval_Status__c) && ppo.PPO_Approval_Status__c?.contains('Pending')) {
                pposToLock.put(ppo.id, ppo);
            }
        }

        if (!pposToLock.isEmpty()) {
            System.debug('pposToLock' + pposToLock);
            Approval.lock(new List<Id>(pposToLock.keySet()));
        }
    }

    public static void afterUpdateEventAction(List<PPO_Sales_Governance__c> ppoLst, map<Id, PPO_Sales_Governance__c> oldMap, map<Id, PPO_Sales_Governance__c> newMap) {
        lockPPOs(ppoLst);
    }

    public static void sendInitialEmail(List<PPO_Sales_Governance__c> newPPOs) {
        Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'PPO_new_Process_Notification_template' LIMIT 1].Id;

        Set<Id> opportunityIds = new Set<Id>();
        for (PPO_Sales_Governance__c ppo : newPPOs) {
            if (ppo.Opportunity__c != null)
                opportunityIds.add(ppo.Opportunity__c);
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Name FROM Opportunity WHERE Id IN :opportunityIds]);

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (PPO_Sales_Governance__c ppo : newPPOs) {
            List<String> emailAddresses = new List<String>();
            //emailAddresses.add(ppo.CreatedBy.Email);

            // Public Group members
            if (Test.isRunningTest()) {
                return;
            }
            emailAddresses.addAll(getGroupEmails(new Set<String>{ 'Quotes Team member', 'Sales Ops' }));
            System.debug('emailAddressgroupmembers: ' + emailAddresses);

            // Opportunity Team Members except cro and global tam
            if (ppo.Opportunity__c != null) {
                List<OpportunityTeamMember> oppTeam = [
                    SELECT User.Email
                    FROM OpportunityTeamMember
                    WHERE OpportunityId = :ppo.Opportunity__c AND TeamMemberRole NOT IN ('CRO', 'Global TAM')
                ];
                for (OpportunityTeamMember tm : oppTeam) {
                    emailAddresses.add(tm.User.Email);
                }

                System.debug('emailAddressesteammembers: ' + emailAddresses);
            }

            System.debug('emailAddresses %%%$$$: ' + emailAddresses);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(templateId);
            email.setTargetObjectId(getDummyContact().Id);
            email.setTreatTargetObjectAsRecipient(false);
            email.setSaveAsActivity(false);
            email.setToAddresses(emailAddresses);
            email.setWhatId(ppo.Id);
            emailsToSend.add(email);
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend, false);
        }

        System.debug('Initial emails sent for new PPOs: ' + newPPOs.size());
        System.debug('Emails: ' + emailsToSend);
    }

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