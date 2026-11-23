public with sharing class OpportunityApprovalManager {

    // ── Inner Types ──────────────────────────────────────────────────────────────

    public class ApprovalRequest {
        @InvocableVariable(required=true)
        public Id opportunityId;

        @InvocableVariable
        public String level; // 'L1' or 'L2' — defaults to 'L1'
    }

    public class ApprovalResult {
        @InvocableVariable public String status;
        @InvocableVariable public String message;
    }

    // ── Flow Entry Point ─────────────────────────────────────────────────────────

    @InvocableMethod(label='Submit Opportunity for Dynamic Approval (ODA)')
    public static List<ApprovalResult> submit(List<ApprovalRequest> requests) {
        ApprovalResult res = new ApprovalResult();

        if (requests == null || requests.isEmpty()) {
            res.status  = 'Error';
            res.message = 'No Opportunity ID provided.';
            return new List<ApprovalResult>{ res };
        }

        Id     oppId = requests[0].opportunityId;
        String level = String.isBlank(requests[0].level) ? 'L1' : requests[0].level.toUpperCase();

        return level == 'L1' ? submitL1(oppId) : submitL2Flow(oppId);
    }

    // ── Trigger Entry Point for L2 ───────────────────────────────────────────────

    public static void submitLevel2(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        for (Opportunity opp : newOpps) {
            if (opp.Opportunity_Approval_Status__c    == 'L1 Approved' &&
                oldMap.get(opp.Id).Opportunity_Approval_Status__c != 'L1 Approved') {
                submitOneL2(opp.Id);
            }
        }
    }

    // ── Private: L1 ─────────────────────────────────────────────────────────────

    private static List<ApprovalResult> submitL1(Id oppId) {
        ApprovalResult res = new ApprovalResult();
        Opportunity opp;

        try {
            opp = fetchOpportunity(oppId);
        } catch (Exception e) {
            res.status  = 'Error';
            res.message = 'Error fetching Opportunity: ' + e.getMessage();
            return new List<ApprovalResult>{ res };
        }

        String salesType = getSalesTypeCategory(opp);
        if (salesType == null) {
            res.status  = 'Error';
            res.message = String.isBlank(opp.Cross_sell1__c)
                ? 'Sales Type is blank on the Opportunity.'
                : 'Unrecognized Sales Type: ' + opp.Cross_sell1__c;
            return new List<ApprovalResult>{ res };
        }

        String   amountCat = getAmountCategory(opp);
        List<Id> l1Ids;
        try {
            l1Ids = resolveApproverIds(opp, salesType, amountCat, 1);
        } catch (Exception e) {
            res.status  = 'Error';
            res.message = 'Error resolving L1 approvers: ' + e.getMessage();
            return new List<ApprovalResult>{ res };
        }

        if (l1Ids == null || l1Ids.isEmpty()) {
            res.status  = 'Error';
            res.message = 'No Level 1 approvers found — Stage: ' + opp.StageName
                + ' | Type: ' + salesType + ' | Amount: ' + amountCat
                + ' | Sub-Region: ' + opp.Sub_Region__c;
            return new List<ApprovalResult>{ res };
        }

        try {
            populateLookupFields(opp, l1Ids);
            update opp;
        } catch (Exception e) {
            res.status  = 'Error';
            res.message = 'Error updating Opportunity approver fields: ' + e.getMessage();
            return new List<ApprovalResult>{ res };
        }

        try {
            recallPending(oppId);
        } catch (Exception e) {
            System.debug('ODA L1: recall error — ' + e.getMessage());
        }

        try {
            String l1ProcessName = 'Secure Agreement'.equalsIgnoreCase(opp.StageName)
                ? 'Opportunity_Dynamic_Approvals_SA_L1'
                : 'ODA_L1_Approval';

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(oppId);
            req.setProcessDefinitionNameOrId(l1ProcessName);
            req.setSkipEntryCriteria(true);
            req.setNextApproverIds(l1Ids);
            req.setComments('Level 1 approval | Stage: ' + opp.StageName
                + ' | Type: ' + salesType + ' | Approvers: ' + l1Ids.size());
            Approval.process(req);

            res.status  = 'Success';
            res.message = 'Submitted for Level 1 approval with ' + l1Ids.size() + ' approver(s).';
        } catch (Exception e) {
            if (e.getMessage().containsIgnoreCase('ALREADY_IN_PROCESS')) {
                res.status  = 'Warning';
                res.message = 'This opportunity is already in an active approval process.';
            } else {
                res.status  = 'Error';
                res.message = e.getMessage();
            }
        }

        return new List<ApprovalResult>{ res };
    }

    // ── Private: L2 (Flow variant) ───────────────────────────────────────────────

    private static List<ApprovalResult> submitL2Flow(Id oppId) {
        ApprovalResult res = new ApprovalResult();
        submitOneL2(oppId);
        res.status  = 'Success';
        res.message = 'L2 submission initiated.';
        return new List<ApprovalResult>{ res };
    }

    private static void submitOneL2(Id oppId) {
        Opportunity opp  = fetchOpportunity(oppId);
        String salesType = getSalesTypeCategory(opp);
        if (salesType == null) {
            System.debug('ODA L2: null salesType for oppId=' + oppId);
            return;
        }

        Boolean isSecureAgreement = 'Secure Agreement'.equalsIgnoreCase(opp.StageName);
        String l2ProcessName = isSecureAgreement
            ? 'Opportunity_Dynamic_Approvals_SA_L2'
            : 'ODA_L2_Approval';

        Integer l2Existing = [
            SELECT COUNT() FROM ProcessInstance
            WHERE  TargetObjectId = :oppId
            AND    ProcessDefinition.DeveloperName = :l2ProcessName
            AND    Status IN ('Pending', 'Approved')
        ];
        if (l2Existing > 0) {
            System.debug('ODA L2: already exists for oppId=' + oppId + ' — skipping.');
            return;
        }

        List<Id> l2Ids = resolveApproverIds(opp, salesType, getAmountCategory(opp), 2);
        if (l2Ids.isEmpty()) {
            System.debug('ODA L2: no approvers found for oppId=' + oppId);
            if (isSecureAgreement) {
                Database.update(
                    new Opportunity(Id = oppId, Second_Approval_Status__c = 'Approved'),
                    System.AccessLevel.SYSTEM_MODE
                );
            } else {
                Database.update(
                    new Opportunity(Id = oppId, Opportunity_Approval_Status__c = 'Approved'),
                    System.AccessLevel.SYSTEM_MODE
                );
            }
            return;
        }

        try {
            populateLookupFields(opp, l2Ids);
            update opp;
        } catch (Exception e) {
            System.debug('ODA L2: field update error — ' + e.getMessage());
            return;
        }

        try {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(oppId);
            req.setProcessDefinitionNameOrId(l2ProcessName);
            req.setSkipEntryCriteria(true);
            req.setNextApproverIds(l2Ids);
            req.setComments('Level 2 approval | Stage: ' + opp.StageName
                + ' | Approvers: ' + l2Ids.size());
            Approval.process(req);
            System.debug('ODA L2: submitted for oppId=' + oppId + ' with ' + l2Ids.size() + ' approver(s) using ' + l2ProcessName);
        } catch (Exception e) {
            System.debug('ODA L2: submit error for oppId=' + oppId + ' — ' + e.getMessage());
        }
    }

    // ── Private Helpers ──────────────────────────────────────────────────────────

    private static Opportunity fetchOpportunity(Id oppId) {
        return [
            SELECT Id, Name, Amount, StageName, Cross_sell1__c,
                   Delivery_Involved__c, Managed_Services_Involved__c,
                   Customer_Services_Involved__c, Hardware_delivery_involved__c,
                   Business_Unit__c, Sub_Region__c, Country__c,
                   Opportunity_Approval_Status__c,
                   CS_Manager__c, Business_Unit_Lead_Testing__c, CS_GM__c,
                   Business_Development_Manager__c, Additional_TAM__c,
                   BusinessUnitLeadRisk__c, Business_Unit_Lead_Engmnt_Exp__c,
                   Business_Unit_Lead_Security__c, BULeadRoaming__c,
                   Commercial_Specialist__c
            FROM   Opportunity
            WHERE  Id = :oppId
            LIMIT  1
        ];
    }

    private static String getSalesTypeCategory(Opportunity opp) {
        // Return raw value for direct matching against custom object records.
        // Blank or unrecognised values return null to surface an error.
        if (String.isBlank(opp.Cross_sell1__c)) return null;
        return opp.Cross_sell1__c;
    }

    private static String getAmountCategory(Opportunity opp) {
        Decimal amt = opp.Amount != null ? opp.Amount : 0;
        return amt < 100000 ? 'Less than 100K' : 'Greater than or equal 100K';
    }

    private static List<Id> resolveApproverIds(
        Opportunity opp, String salesType, String amountCat, Integer level
    ) {
        List<Opportunity_Dynamic_Approvals__c> allRecs = [
            SELECT Opportunity_Stage__c, Sales_Type__c, Amount__c,
                   BU__c, Sub_Region__c,
                   Delivery_Involved__c, X3rd_Party_Involved__c,
                   MS_Involved__c, CS_Involved__c,
                   X3rd_Party_Approver_L1__c, CFO__c, CRO__c,
                   CS_Approver_L1__c, Delivery_Approver_L1__c,
                   MS_Approver_L1__c, PM_Approver_L1__c, Sales_GM_L1__c,
                   X3rd_Party_Approver_L2__c, CS_Approver_L2__c,
                   Delivery_Approver_L2__c, MS_Approver_L2__c, PM_L2__c
            FROM   Opportunity_Dynamic_Approvals__c
        ];
        if (allRecs.isEmpty()) return new List<Id>();

        final Set<String> DEVELOP_STAGES = new Set<String>{
            'White Space', 'Identify the Opportunity', 'Validate the Opportunity',
            'Qualify the Opportunity', 'Develop Solution'
        };
        String approvalStage = DEVELOP_STAGES.contains(opp.StageName) ? 'Develop Solution' : opp.StageName;
        String oppSubRegion  = String.isNotBlank(opp.Sub_Region__c) ? opp.Sub_Region__c.trim() : '';

        // BU as multi-select picklist (semicolon-delimited)
        List<String> oppBUList = new List<String>();
        if (String.isNotBlank(opp.Business_Unit__c)) {
            for (String bu : opp.Business_Unit__c.split(';')) {
                oppBUList.add(bu.trim());
            }
        }

        List<Opportunity_Dynamic_Approvals__c> specificMatches = new List<Opportunity_Dynamic_Approvals__c>();
        List<Opportunity_Dynamic_Approvals__c> globalMatches   = new List<Opportunity_Dynamic_Approvals__c>();

        for (Opportunity_Dynamic_Approvals__c r : allRecs) {
            if (String.isBlank(r.Opportunity_Stage__c) || !r.Opportunity_Stage__c.equalsIgnoreCase(approvalStage)) continue;
            if (String.isBlank(r.Sales_Type__c)        || !r.Sales_Type__c.equalsIgnoreCase(salesType))            continue;
            if (String.isBlank(r.Amount__c)            || !r.Amount__c.equalsIgnoreCase(amountCat))                continue;

            // BU: 'All' = wildcard; otherwise the record's BU must appear in opp's multi-select BU list
            if (String.isNotBlank(r.BU__c) && !r.BU__c.equalsIgnoreCase('All')) {
                Boolean buMatch = false;
                for (String bu : oppBUList) {
                    if (r.BU__c.equalsIgnoreCase(bu)) { buMatch = true; break; }
                }
                if (!buMatch) continue;
            }

            // Involved flags: only exclude when the record requires 'Yes' but the opp doesn't have 'Yes'
            if (r.Delivery_Involved__c   == 'Yes' && opp.Delivery_Involved__c          != 'Yes') continue;
            if (r.X3rd_Party_Involved__c == 'Yes' && opp.Hardware_delivery_involved__c != 'Yes') continue;
            if (r.MS_Involved__c         == 'Yes' && opp.Managed_Services_Involved__c  != 'Yes') continue;
            if (r.CS_Involved__c         == 'Yes' && opp.Customer_Services_Involved__c != 'Yes') continue;

            if (String.isNotBlank(r.Sub_Region__c) && r.Sub_Region__c.equalsIgnoreCase('All')) {
                globalMatches.add(r);
            } else if (String.isNotBlank(r.Sub_Region__c) && r.Sub_Region__c.equalsIgnoreCase(oppSubRegion)) {
                specificMatches.add(r);
            }
        }

        List<Opportunity_Dynamic_Approvals__c> matched = new List<Opportunity_Dynamic_Approvals__c>();
        if (!specificMatches.isEmpty()) {
            matched.addAll(specificMatches);
            matched.addAll(globalMatches);
        } else {
            matched.addAll(globalMatches);
        }
        if (matched.isEmpty()) return new List<Id>();

        // Collect approver emails — deduplicated per level
        List<String> emails = new List<String>();
        Set<String>  seen   = new Set<String>();

        for (Opportunity_Dynamic_Approvals__c r : matched) {
            if (level == 1) {
                collectEmails(emails, seen, r.X3rd_Party_Approver_L1__c);
                collectEmails(emails, seen, r.CFO__c);
                collectEmails(emails, seen, r.CRO__c);
                collectEmails(emails, seen, r.CS_Approver_L1__c);
                collectEmails(emails, seen, r.Delivery_Approver_L1__c);
                collectEmails(emails, seen, r.MS_Approver_L1__c);
                collectEmails(emails, seen, r.PM_Approver_L1__c);
                collectEmails(emails, seen, r.Sales_GM_L1__c);
            } else {
                collectEmails(emails, seen, r.X3rd_Party_Approver_L2__c);
                collectEmails(emails, seen, r.CS_Approver_L2__c);
                collectEmails(emails, seen, r.Delivery_Approver_L2__c);
                collectEmails(emails, seen, r.MS_Approver_L2__c);
                collectEmails(emails, seen, r.PM_L2__c);
                collectEmails(emails, seen, r.CFO__c);
                collectEmails(emails, seen, r.CRO__c);
            }
        }
        if (emails.isEmpty()) return new List<Id>();

        // Resolve emails → active User IDs
        Map<String, Id> emailToId = new Map<String, Id>();
        for (User u : [
            SELECT Id, Email, Username
            FROM   User
            WHERE  (Email IN :emails OR Username IN :emails)
            AND    IsActive = true
        ]) {
            emailToId.put(u.Email.toLowerCase(), u.Id);
            emailToId.put(u.Username.toLowerCase(), u.Id);
        }

        List<Id> approverIds = new List<Id>();
        Set<Id>  addedIds    = new Set<Id>();
        for (String e : emails) {
            Id uid = emailToId.get(e);
            if (uid != null && addedIds.add(uid)) approverIds.add(uid);
        }
        return approverIds;
    }

    // Populates existing Opportunity lookup fields with resolved approver User IDs
    private static void populateLookupFields(Opportunity opp, List<Id> approverIds) {
        opp.CS_Manager__c                    = null;
        opp.Business_Unit_Lead_Testing__c    = null;
        opp.CS_GM__c                         = null;
        opp.Business_Development_Manager__c  = null;
        opp.Additional_TAM__c                = null;
        opp.BusinessUnitLeadRisk__c          = null;
        opp.Business_Unit_Lead_Engmnt_Exp__c = null;
        opp.Business_Unit_Lead_Security__c   = null;
        opp.BULeadRoaming__c                 = null;
        opp.Commercial_Specialist__c         = null;

        for (Integer i = 0; i < approverIds.size() && i < 10; i++) {
            if      (i == 0) opp.CS_Manager__c                    = approverIds[i];
            else if (i == 1) opp.Business_Unit_Lead_Testing__c    = approverIds[i];
            else if (i == 2) opp.CS_GM__c                         = approverIds[i];
            else if (i == 3) opp.Business_Development_Manager__c  = approverIds[i];
            else if (i == 4) opp.Additional_TAM__c                = approverIds[i];
            else if (i == 5) opp.BusinessUnitLeadRisk__c          = approverIds[i];
            else if (i == 6) opp.Business_Unit_Lead_Engmnt_Exp__c = approverIds[i];
            else if (i == 7) opp.Business_Unit_Lead_Security__c   = approverIds[i];
            else if (i == 8) opp.BULeadRoaming__c                 = approverIds[i];
            else if (i == 9) opp.Commercial_Specialist__c         = approverIds[i];
        }
    }

    private static void collectEmails(List<String> emails, Set<String> seen, String raw) {
        if (String.isBlank(raw)) return;
        for (String e : raw.split('[;,]')) {
            String n = e.trim().toLowerCase();
            if (String.isNotBlank(n) && seen.add(n)) emails.add(n);
        }
    }

    private static void recallPending(Id recordId) {
        List<ProcessInstance> pending = [
            SELECT Id, (SELECT Id FROM Workitems)
            FROM   ProcessInstance
            WHERE  TargetObjectId = :recordId AND Status = 'Pending'
        ];
        if (pending.isEmpty()) return;

        List<Approval.ProcessWorkitemRequest> recalls = new List<Approval.ProcessWorkitemRequest>();
        for (ProcessInstance pi : pending) {
            for (ProcessInstanceWorkitem wi : pi.Workitems) {
                Approval.ProcessWorkitemRequest r = new Approval.ProcessWorkitemRequest();
                r.setAction('Removed');
                r.setWorkitemId(wi.Id);
                recalls.add(r);
            }
        }
        if (!recalls.isEmpty()) Approval.process(recalls);
    }
}