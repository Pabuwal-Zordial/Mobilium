public without sharing class DynamicApprovalEngine {

    /*
    ============================================================
    CONSTANTS — update to match your org's approval process API names
    ============================================================
    */
    @TestVisible static final String L1_PROCESS_API_NAME    = 'Opportunity_Dynamic_Approvals_L1';
    @TestVisible static final String L2_PROCESS_API_NAME    = 'Opportunity_Dynamic_Approvals_L2';
    @TestVisible static final String SA_L1_PROCESS_API_NAME = 'Opportunity_Dynamic_Approvals_SA_L1';
    @TestVisible static final String SA_L2_PROCESS_API_NAME = 'Opportunity_Dynamic_Approvals_SA_L2';


    private static final Set<String> STAGE_4_AND_EARLIER = new Set<String>{
        'White Space', 'Identify the Opportunity', 'Validate the Opportunity',
        'Qualify the Opportunity', 'Develop Solution'
    };

    private static final Set<String> BLOCKED_APPROVAL_STAGES = new Set<String>{
        'Propose Solution', 'PO & Signed Contract', 'Finance Review',
        'Won & Closed', 'Lost', 'Deleted', 'Deleted Recon'
    };

    private static final Map<String, Integer> STAGE_NUMBERS = new Map<String, Integer>{
        'White Space'              => 0, 'Identify the Opportunity' => 1,
        'Validate the Opportunity' => 2, 'Qualify the Opportunity'  => 3,
        'Develop Solution'         => 4, 'Propose Solution'          => 5,
        'Secure Agreement'         => 6, 'PO & Signed Contract'      => 7,
        'Finance Review'           => 8, 'Won & Closed'              => 9
    };

    private static final Set<String> CLOSED_LOST_STAGES = new Set<String>{
        'Lost', 'Deleted', 'Deleted Recon'
    };

    // Values on Second_Approval_Status__c (Secure Agreement / second-level approval field)
    // that should be treated as "fully approved". 'Approved - 2nd' was added alongside the
    // original 'Approved' value so both are honored wherever second-approval completion is checked.
    private static final Set<String> SECOND_APPROVAL_APPROVED_VALUES = new Set<String>{
        'approved', 'approved - 2nd'
    };

    /*
    ============================================================
    STATUS VALUES (user-facing)
      Submitted   — L1 or L2 submitted, waiting for approvers
      L1 Approved — all L1 approvers approved (transitional)
      Approved    — all required levels fully approved
      Rejected    — any approver at any level rejected
    ============================================================
    */

    /*
    ============================================================
    INNER CLASSES
    ============================================================
    */

    public class ApprovalRequest {
        @InvocableVariable(required=true)
        public Id opportunityId;
    }

    public class ApprovalResult {
        @InvocableVariable public String status;
        @InvocableVariable public String message;
    }

    // Used by the standard approval process Final Approval / Rejection Actions.
    // outcome: 'Approved' or 'Rejected'
    // level:   'L1' or 'L2'
    public class ApprovalOutcomeRequest {
        @InvocableVariable(required=true) public Id     opportunityId;
        @InvocableVariable(required=true) public String outcome;
        @InvocableVariable(required=true) public String level;
        @InvocableVariable               public String comments;
        @InvocableVariable               public Id     actorId;
    }

    /*
    ============================================================
    SA-ONLY FLOW ENTRY POINT
    Called exclusively from Secure_Agreement_Approval_Flow.
    Handles Stage 6 (Secure Agreement) submission in isolation.
    ============================================================
    */

    public static List<ApprovalResult> submitSAApproval(List<ApprovalRequest> requests) {
        ApprovalResult result = new ApprovalResult();

        if (requests == null || requests.isEmpty()) {
            result.status  = 'Error';
            result.message = 'No opportunity ID provided.';
            return new List<ApprovalResult>{ result };
        }

        Id          oppId = requests[0].opportunityId;
        Opportunity opp;

        try {
            opp = fetchOpportunity(oppId);
        } catch (Exception e) {
            result.status  = 'Error';
            result.message = 'Error fetching Opportunity: ' + e.getMessage();
            return new List<ApprovalResult>{ result };
        }

        if (!'Secure Agreement'.equalsIgnoreCase(opp.StageName)) {
            result.status  = 'Error';
            result.message = 'This approval button is only for the Secure Agreement stage.';
            return new List<ApprovalResult>{ result };
        }

        if ('Pending'.equalsIgnoreCase(opp.Second_Approval_Status__c) ||
            'L1 Approved'.equalsIgnoreCase(opp.Second_Approval_Status__c)) {
            result.status  = 'Warning';
            result.message = 'Secure Agreement approval is already in progress.';
            return new List<ApprovalResult>{ result };
        }

        String saValidationMsg = validatePreApprovalConditions(opp);
        if (saValidationMsg != null) {
            result.message = saValidationMsg;
            return new List<ApprovalResult>{ result };
        }

        String salesType = getSalesTypeCategory(opp);
        if (salesType == null) {
            result.status  = 'Error';
            result.message = String.isBlank(opp.Cross_sell1__c)
                ? 'Sales Type is blank. Cannot determine approvers.'
                : 'Unrecognized Sales Type: ' + opp.Cross_sell1__c;
            return new List<ApprovalResult>{ result };
        }

        String   amountCat   = getAmountCategory(opp);
        List<Id> approverIds = new List<Id>();

        try {
            approverIds = resolveApproverIds(opp, salesType, amountCat, 1);
        } catch (Exception e) {
            result.status  = 'Error';
            result.message = 'Error resolving approvers: ' + e.getMessage();
            return new List<ApprovalResult>{ result };
        }

        if (approverIds == null || approverIds.isEmpty()) {
            result.status  = 'Error';
            result.message = 'No approvers were found for this Opportunity, as it does not meet the defined approval criteria';
            return new List<ApprovalResult>{ result };
        }

        try {
            populateRelatedApprovers(oppId, approverIds);
        } catch (Exception e) {
            result.status  = 'Error';
            result.message = 'Error updating approver fields: ' + e.getMessage();
            return new List<ApprovalResult>{ result };
        }

        try {
            recallPendingApprovals(oppId);

            Map<Id, Id> saL1WorkitemIds = submitToStandardProcess(oppId, approverIds, SA_L1_PROCESS_API_NAME, 'L1');

            // Explicitly lock the record so it stays locked for the entire duration of this
            // level's review. Submitting one ProcessSubmitRequest per approver creates several
            // parallel ProcessInstances at the same level - when a multi-approver level has one
            // approver act while siblings are still Pending, Salesforce's native auto-unlock can
            // fire early (it isn't designed around several simultaneous instances on one record),
            // leaving the record editable even though the approval is still genuinely in progress.
            if (!Approval.isLocked(oppId)) {
                Approval.lock(oppId);
            }

            updatePendingApprovers(oppId, approverIds);

            sendApprovalRequestEmails(approverIds, opp, 'L1', saL1WorkitemIds);

            ApprovalNotificationSender.sendApprovalRequestToUsers(approverIds, oppId, opp.Name, 'L1', saL1WorkitemIds);

            Database.update(
                new Opportunity(Id = oppId, Second_Approval_Status__c = 'Pending', Submitted_Date__c = DateTime.now()),
                System.AccessLevel.SYSTEM_MODE
            );

            result.status  = 'Success';
            result.message = 'Approval Submitted Successfully';

        } catch (DmlException e) {
            if (e.getMessage().contains('ALREADY_IN_PROCESS')) {
                result.status  = 'Error';
                result.message = 'This record is already in an active approval process. Please recall it first.';
            } else {
                result.status  = 'Error';
                result.message = e.getMessage();
            }
        } catch (Exception e) {
            result.status  = 'Error';
            result.message = e.getMessage();
        }

        return new List<ApprovalResult>{ result };
    }

    /*
    ============================================================
    FLOW ENTRY POINT
    Submits to the standard approval process — one
    ProcessSubmitRequest per L1 approver so all receive their
    workitem simultaneously regardless of how many approvers exist.
    ============================================================
    */

    @InvocableMethod(label='Submit Dynamic Approval')
    public static List<ApprovalResult> submitApproval(List<ApprovalRequest> requests) {

        ApprovalResult result = new ApprovalResult();

        if (requests == null || requests.isEmpty()) {
            result.status  = 'Error';
            result.message = 'No opportunity ID provided.';
            return new List<ApprovalResult>{ result };
        }

        Id          oppId = requests[0].opportunityId;
        Opportunity opp;

        try {
            opp = fetchOpportunity(oppId);
        } catch (Exception e) {
            result.status  = 'Error';
            result.message = 'Error fetching Opportunity: ' + e.getMessage();
            return new List<ApprovalResult>{ result };
        }

        // Block re-submission if approval is already running.
        // Secure Agreement stage uses Second_Approval_Status__c; all other stages use Opportunity_Approval_Status__c.
        // Always allow re-submission when the prior approval was rejected OR fully approved
        // (e.g. the Opportunity moved back to an earlier stage and is being resubmitted as a
        // brand-new approval cycle).
        Boolean isSecureAgreement = 'Secure Agreement'.equalsIgnoreCase(opp.StageName);
        Boolean isPriorRejected   = isSecureAgreement
            ? 'Rejected'.equalsIgnoreCase(opp.Second_Approval_Status__c)
            : 'Rejected'.equalsIgnoreCase(opp.Opportunity_Approval_Status__c);
        Boolean isPriorApproved   = isSecureAgreement
            ? isSecondApprovalApproved(opp.Second_Approval_Status__c)
            : 'Approved'.equalsIgnoreCase(opp.Opportunity_Approval_Status__c);

        if (!isPriorRejected && !isPriorApproved &&
            isApprovalInProgress(oppId, opp.Opportunity_Approval_Status__c, opp.Second_Approval_Status__c, opp.StageName)) {
            result.status  = 'Error';
            result.message = 'Approval is already in progress for this record. You cannot resubmit until it is completed or rejected.';
            return new List<ApprovalResult>{ result };
        }

        String validationMsg = validatePreApprovalConditions(opp);
        if (validationMsg != null) {
            result.message = validationMsg;
            return new List<ApprovalResult>{ result };
        }

        String salesType = getSalesTypeCategory(opp);
        if (salesType == null) {
            result.status  = 'Error';
            result.message = String.isBlank(opp.Cross_sell1__c)
                ? 'Sales Type is blank. Cannot determine approvers.'
                : 'Unrecognized Sales Type: ' + opp.Cross_sell1__c;
            return new List<ApprovalResult>{ result };
        }

        String   amountCat   = getAmountCategory(opp);
        List<Id> approverIds = new List<Id>();

        try {
            approverIds = resolveApproverIds(opp, salesType, amountCat, 1);
        } catch (Exception e) {
            result.status  = 'Error';
            result.message = 'Error resolving L1 approvers: ' + e.getMessage();
            return new List<ApprovalResult>{ result };
        }

        if (approverIds == null || approverIds.isEmpty()) {
            result.status  = 'Error';
            result.message = 'No approvers were found for this Opportunity, as it does not meet the defined approval criteria';
            return new List<ApprovalResult>{ result };
        }

        try {
            populateRelatedApprovers(oppId, approverIds);
        } catch (Exception e) {
            result.status  = 'Error';
            result.message = 'Error updating approver fields: ' + e.getMessage();
            return new List<ApprovalResult>{ result };
        }

        try {
            // Cancel any currently active standard process instances for a clean re-submit
            recallPendingApprovals(oppId);

            // Submit one ProcessSubmitRequest per approver — all receive workitems simultaneously
            String l1Process = 'Secure Agreement'.equalsIgnoreCase(opp.StageName)
                ? SA_L1_PROCESS_API_NAME
                : L1_PROCESS_API_NAME;
            Map<Id, Id> l1WorkitemIds = submitToStandardProcess(oppId, approverIds, l1Process, 'L1');

            // Explicitly lock the record so it stays locked for the entire duration of this
            // level's review. Submitting one ProcessSubmitRequest per approver creates several
            // parallel ProcessInstances at the same level - when a multi-approver level has one
            // approver act while siblings are still Pending, Salesforce's native auto-unlock can
            // fire early (it isn't designed around several simultaneous instances on one record),
            // leaving the record editable even though the approval is still genuinely in progress.
            if (!Approval.isLocked(oppId)) {
                Approval.lock(oppId);
            }

            updatePendingApprovers(oppId, approverIds);

            sendApprovalRequestEmails(approverIds, opp, 'L1', l1WorkitemIds);

            ApprovalNotificationSender.sendApprovalRequestToUsers(approverIds, oppId, opp.Name, 'L1', l1WorkitemIds);

            if ('Secure Agreement'.equalsIgnoreCase(opp.StageName)) {
                Database.update(
                    new Opportunity(Id = oppId, Second_Approval_Status__c = 'Pending', Submitted_Date__c = DateTime.now()),
                    System.AccessLevel.SYSTEM_MODE
                );
            } else {
                // A fresh non-SA (L1) submission starts a brand-new approval cycle for this
                // Opportunity. If it previously went all the way through a Secure Agreement
                // (Stage 6) approval and was then moved back to an earlier stage, the old
                // Second_Approval_Status__c value (e.g. 'Approved') is now stale and must be
                // cleared back to blank so the record doesn't appear to still carry a
                // completed second approval from the prior cycle. It will be re-populated the
                // next time this Opportunity reaches Secure Agreement and is submitted again.
                // Submitted_Date__c is also reset here to the actual moment of this fresh
                // submission - without this it would otherwise keep showing whatever value
                // survived from the previous (already completed/rejected) approval cycle.
                Database.update(
                    new Opportunity(
                        Id = oppId,
                        Opportunity_Approval_Status__c = 'Submitted',
                        Second_Approval_Status__c      = null,
                        Submitted_Date__c              = DateTime.now()
                    ),
                    System.AccessLevel.SYSTEM_MODE
                );
            }

            result.status  = 'Success';
            result.message = 'Approval Submitted Successfully';

        } catch (DmlException e) {
            if (e.getMessage().contains('ALREADY_IN_PROCESS')) {
                result.status  = 'Error';
                result.message = 'This record is already in an active standard approval process. Please recall it first.';
            } else {
                result.status  = 'Error';
                result.message = e.getMessage();
            }
        } catch (Exception e) {
            result.status  = 'Error';
            result.message = e.getMessage();
        }

        return new List<ApprovalResult>{ result };
    }

    /*
    ============================================================
    APPROVAL PROCESS OUTCOME HANDLER
    Call this from the standard approval process:
      Final Approval Action  → outcome='Approved', level='L1' (or 'L2')
      Rejection Action       → outcome='Rejected', level='L1' (or 'L2')

    Logic:
      L1 Approved — if all L1 approvers have approved:
                      → if L2 approvers exist: auto-submit L2, keep status 'Pending Approval'
                      → if no L2 approvers:    set status 'Approved' (fully done)
      L2 Approved — all levels done → set status 'Approved'
      Rejected    — any level: recall remaining workitems, set status 'Rejected'
    ============================================================
    */

    public static void handleApprovalOutcome(List<ApprovalOutcomeRequest> requests) {
        for (ApprovalOutcomeRequest req : requests) {
            if (req == null || req.opportunityId == null) continue;
            if (req.outcome == 'Approved') {
                handleApproved(req.opportunityId, req.level);
            } else if (req.outcome == 'Rejected') {
                handleRejected(req.opportunityId, req.actorId, req.comments);
            }
        }
    }

    /*
    ============================================================
    TRIGGER ENTRY POINTS
    Called from OpportunityTrigger when the approval process
    FieldUpdate changes Opportunity_Approval_Status__c.
    ============================================================
    */

    // Called when Dynamic_L1_Approved FieldUpdate sets Opportunity_Approval_Status__c to 'L1 Approved' (non-SA stages)
    public static void handleL1Approved(List<Id> oppIds) {
        for (Id oppId : oppIds) {
            // Each L1 approver has their own independent ProcessInstance, so this fires on the
            // FIRST one to act, not the last. If others are still pending, revert to 'Submitted'
            // (the pre-approval in-progress value) so the next approver's own completion re-fires
            // this same check — only the last one through actually finalizes L1.
            if (hasPendingSiblings(oppId, L1_PROCESS_API_NAME)) {
                Database.update(
                    new Opportunity(Id = oppId, Opportunity_Approval_Status__c = 'Submitted'),
                    System.AccessLevel.SYSTEM_MODE
                );
                // Re-assert the lock every time a sibling acts while others are still pending -
                // Salesforce's native auto-unlock can fire early with several parallel
                // ProcessInstances at one level (see submitApproval's lock comment). Doing it
                // here too (not just at initial submission) also re-locks records that were
                // already mid-cycle before that submission-time fix existed.
                if (!System.isFuture() && !System.isBatch()) {
                    relockRecordAsync(oppId);
                }
                refreshPendingApprovers(oppId);
                continue;
            }
            // Synchronously set the correct final status so the record never shows
            // 'L1 Approved' transiently while the @future is queued.
            if (hasL2Approvers(oppId)) {
                Database.update(
                    new Opportunity(Id = oppId, Opportunity_Approval_Status__c = 'Pending Approval'),
                    System.AccessLevel.SYSTEM_MODE
                );
            } else {
                Database.update(
                    new Opportunity(Id = oppId, Opportunity_Approval_Status__c = 'Approved'),
                    System.AccessLevel.SYSTEM_MODE
                );
            }
            refreshPendingApprovers(oppId);
            // Submit L2 in a new transaction so L1's ProcessInstance has fully finalized
            // before Approval.process() is called. Without this, the call happens while
            // L1 is still Pending and throws ALREADY_IN_PROCESS, leaving the record unlocked.
            submitLevel2Async(oppId, false);
        }
    }

    // Called when Opportunity_Approval_Status__c changes to 'Approved' (non-SA stages)
    // Covers both L1-only path (status set by submitLevel2Async) and L2 path (Dynamic_L2_Approved field update)
    public static void handleNonSAApproved(List<Id> oppIds) {
        for (Id oppId : oppIds) {
            // Each L2 approver has their own independent ProcessInstance too — if others are
            // still pending, revert to 'Pending Approval' instead of leaving 'Approved' sitting
            // prematurely; the next approver's completion will re-fire this check.
            if (hasPendingSiblings(oppId, L2_PROCESS_API_NAME)) {
                Database.update(
                    new Opportunity(Id = oppId, Opportunity_Approval_Status__c = 'Pending Approval'),
                    System.AccessLevel.SYSTEM_MODE
                );
                if (!System.isFuture() && !System.isBatch()) {
                    relockRecordAsync(oppId);
                }
                refreshPendingApprovers(oppId);
                continue;
            }
            refreshPendingApprovers(oppId);
            Opportunity opp = [SELECT OwnerId, Name FROM Opportunity WHERE Id = :oppId LIMIT 1];
            ApprovalNotificationSender.sendApprovalOutcome(oppId, opp.Name, opp.OwnerId, 'L2_APPROVED');
            sendNonSAApprovedEmail(oppId);
        }
    }

    // Called when Dynamic_SA_L1_Approved FieldUpdate sets Second_Approval_Status__c to 'L1 Approved' (Stage 6 only)
    public static void handleSAL1Approved(List<Id> oppIds) {
        for (Id oppId : oppIds) {
            if (hasPendingSiblings(oppId, SA_L1_PROCESS_API_NAME)) {
                Database.update(
                    new Opportunity(Id = oppId, Second_Approval_Status__c = 'Pending'),
                    System.AccessLevel.SYSTEM_MODE
                );
                if (!System.isFuture() && !System.isBatch()) {
                    relockRecordAsync(oppId);
                }
                refreshPendingApprovers(oppId);
                continue;
            }
            refreshPendingApprovers(oppId);
            // Same async pattern as non-SA — ensures SA L1 ProcessInstance is fully closed
            // before SA L2 Approval.process() is called. Submitting SA L2 below can itself
            // trigger a nested re-entry into this same method (a metadata field-update name
            // collision re-fires the SA L1 transition) — guard so that nested call doesn't try
            // to invoke this @future method a second time from within a future context.
            if (!System.isFuture() && !System.isBatch()) {
                submitLevel2Async(oppId, true);
            }
        }
    }

    // Called when Dynamic_SA_L2_Approved FieldUpdate sets Second_Approval_Status__c to 'Approved' (Stage 6 L2 fully approved)
    public static void handleSAApproved(List<Id> oppIds) {
        for (Id oppId : oppIds) {
            if (hasPendingSiblings(oppId, SA_L2_PROCESS_API_NAME)) {
                // Matches the in-progress value submitLevel2Async already documents for this
                // window: "Second_Approval_Status__c stays 'L1 Approved' until all SA L2 approvers act".
                Database.update(
                    new Opportunity(Id = oppId, Second_Approval_Status__c = 'L1 Approved'),
                    System.AccessLevel.SYSTEM_MODE
                );
                if (!System.isFuture() && !System.isBatch()) {
                    relockRecordAsync(oppId);
                }
                refreshPendingApprovers(oppId);
                continue;
            }
            refreshPendingApprovers(oppId);
            Opportunity opp = [SELECT OwnerId, Name FROM Opportunity WHERE Id = :oppId LIMIT 1];
            ApprovalNotificationSender.sendApprovalOutcome(oppId, opp.Name, opp.OwnerId, 'L2_APPROVED');
            sendSAApprovedEmail(oppId);
        }
    }

    // Submits L2 in a new transaction so L1's ProcessInstance has fully finalized before Approval.process() is called.
    // Without this, the call happens while L1 is still Pending and throws ALREADY_IN_PROCESS, leaving the record unlocked.
    @future
    private static void submitLevel2Async(Id oppId, Boolean isSA) {
        Boolean l2Submitted = submitLevel2Custom(oppId);
        if (!l2Submitted) {
            // No L2 approvers found — SA needs status update; non-SA status already set synchronously in handleL1Approved
            if (isSA) {
                Database.update(
                    new Opportunity(Id = oppId, Second_Approval_Status__c = 'Approved'),
                    System.AccessLevel.SYSTEM_MODE
                );
            }
            if (Approval.isLocked(oppId)) {
                Approval.unlock(oppId);
            }
        } else if (!isSA) {
            // L2 submitted — restore to 'Submitted' while L2 approvers review
            Database.update(
                new Opportunity(Id = oppId, Opportunity_Approval_Status__c = 'Submitted'),
                System.AccessLevel.SYSTEM_MODE
            );
        }
        // SA with l2Submitted=true: Second_Approval_Status__c stays 'L1 Approved' until all SA L2 approvers act
    }

    // Re-asserts the lock in a NEW transaction, run after this one (including the in-progress
    // Approval.process() call that triggered this whole chain) has fully committed. A synchronous
    // Approval.lock() call from inside a trigger fired by an approval FieldUpdate gets silently
    // overridden - the platform's own native unlock evaluation for the completing ProcessInstance
    // runs AFTER the FieldUpdate/trigger step, in the same transaction, so it wins regardless of
    // what was locked moments earlier. Deferring to @future (same pattern as submitLevel2Async,
    // for the same class of ordering problem) sidesteps that entirely.
    @future
    private static void relockRecordAsync(Id oppId) {
        if (!Approval.isLocked(oppId)) {
            Approval.lock(oppId);
        }
    }

    // Called when Dynamic_L1_Rejected or Dynamic_L2_Rejected FieldUpdate sets status to 'Rejected'
    public static void handleRejectedStatus(List<Id> oppIds) {
        for (Id oppId : oppIds) {
            Opportunity opp = [SELECT StageName, OwnerId, Name FROM Opportunity WHERE Id = :oppId LIMIT 1];

            try {
                // Reject the other pending siblings (not recall) — they should show as
                // "Rejected" in approval history, since the whole request is now rejected,
                // not pulled back by the submitter.
                rejectPendingApprovals(oppId);
            } catch (Exception e) {
                System.debug('DynamicApprovalEngine handleRejectedStatus: reject-siblings failed — ' + e.getMessage());
            }

            // Defense-in-depth: each sibling's own final-rejection FieldUpdate re-asserts the
            // same 'Rejected' value, but re-assert it explicitly here too in case any process's
            // rejection action is misconfigured and leaves the field blank instead.
            Database.update(
                'Secure Agreement'.equalsIgnoreCase(opp.StageName)
                    ? new Opportunity(Id = oppId, Second_Approval_Status__c = 'Rejected')
                    : new Opportunity(Id = oppId, Opportunity_Approval_Status__c = 'Rejected'),
                System.AccessLevel.SYSTEM_MODE
            );

            refreshPendingApprovers(oppId);

            // Rejected By = running user (the approver who rejected), Date = today
            String rejectorName  = (String.isNotBlank(UserInfo.getFirstName()) ? UserInfo.getFirstName() + ' ' : '') + UserInfo.getLastName();
            String rejectionDate = System.today().format();
            String comments      = null;
            List<ProcessInstanceStep> steps = [
                SELECT Comments
                FROM   ProcessInstanceStep
                WHERE  ProcessInstance.TargetObjectId = :oppId
                AND    StepStatus = 'Rejected'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!steps.isEmpty()) {
                comments = steps[0].Comments;
            }

            sendRejectionEmail(oppId, rejectorName, comments, rejectionDate);

            ApprovalNotificationSender.sendApprovalOutcome(oppId, opp.Name, opp.OwnerId, 'REJECTED');
        }
    }

    // Called when a manually-recalled approver's own "Recalled" FieldUpdate blanks
    // Opportunity_Approval_Status__c or Second_Approval_Status__c while it was still an
    // in-progress value (Submitted / L1 Approved / Pending Approval / Pending). Because
    // submission creates one independent ProcessInstance per approver, a lone recall only
    // cancels the recaller's own instance — this cascades the recall to the rest so every
    // pending approver is removed, not just one.
    public static void handleRecalledStatus(List<Id> oppIds) {
        for (Id oppId : oppIds) {
            try {
                recallPendingApprovals(oppId);
            } catch (Exception e) {
                System.debug('DynamicApprovalEngine handleRecalledStatus: recall failed — ' + e.getMessage());
            }
            refreshPendingApprovers(oppId);
        }
    }

    // Called by UpdateOppsPendingApprovalsBatch for Opportunities whose approval work item was
    // reassigned to a new approver. Reassignment only changes ProcessInstanceWorkitem /
    // ProcessInstanceStep (neither object is triggerable), so nothing recomputes
    // Pending_Approvers__c in real time for these Dynamic Approval processes — this
    // batch-driven catch-up is what keeps it showing the current assignee.
    public static void handleReassigned(Set<Id> oppIds) {
        for (Id oppId : oppIds) {
            refreshPendingApprovers(oppId);
        }
    }

    private static void handleApproved(Id oppId, String level) {
        // Re-fetch with row lock to prevent duplicate processing when two approvers
        // approve at exactly the same time
        Opportunity opp = [
            SELECT Opportunity_Approval_Status__c, Second_Approval_Status__c, StageName, Name, OwnerId,
                   Delivery_Involved__c, Managed_Services_Involved__c, Customer_Services_Involved__c
            FROM   Opportunity
            WHERE  Id = :oppId
            LIMIT  1
            FOR UPDATE
        ];

        Boolean isSecureAgreement = 'Secure Agreement'.equalsIgnoreCase(opp.StageName);

        // Only proceed when the record is still in an active approval state
        if (isSecureAgreement) {
            if (!'Pending'.equalsIgnoreCase(opp.Second_Approval_Status__c)) return;
        } else {
            String currentStatus = opp.Opportunity_Approval_Status__c;
            if (!'Submitted'.equalsIgnoreCase(currentStatus) && !'L1 Approved'.equalsIgnoreCase(currentStatus) && !'Pending Approval'.equalsIgnoreCase(currentStatus)) return;
        }

        // Determine which process definition to check pending workitems for
        String processName;
        if (isSecureAgreement) {
            processName = (level == 'L1') ? SA_L1_PROCESS_API_NAME : SA_L2_PROCESS_API_NAME;
        } else {
            processName = (level == 'L1') ? L1_PROCESS_API_NAME : L2_PROCESS_API_NAME;
        }

        // Count workitems still awaiting action for THIS level's process
        List<ProcessInstance> pendingInstances = [
            SELECT Id
            FROM   ProcessInstance
            WHERE  TargetObjectId                  = :oppId
            AND    Status                          = 'Pending'
            AND    ProcessDefinition.DeveloperName = :processName
        ];

        if (!pendingInstances.isEmpty()) {
            // Other approvers at this level have not yet acted — nothing to do yet
            return;
        }

        if (level == 'L1') {
            // All L1 approvers have approved — for non-Secure Agreement, mark intermediate L1 Approved state
            if (!isSecureAgreement) {
                Database.update(
                    new Opportunity(Id = oppId, Opportunity_Approval_Status__c = 'L1 Approved'),
                    System.AccessLevel.SYSTEM_MODE
                );
            }

            Boolean l2Submitted = submitLevel2Custom(oppId);

            if (!l2Submitted) {
                // No L2 approvers — fully approved
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
                if (Approval.isLocked(oppId)) {
                    Approval.unlock(oppId);
                }
                ApprovalNotificationSender.sendApprovalOutcome(oppId, opp.Name, opp.OwnerId, 'L2_APPROVED');
                if (isSecureAgreement) {
                    sendSAApprovedEmail(oppId);
                } else {
                    sendNonSAApprovedEmail(oppId);
                }
            } else {
                // L2 submitted — waiting for L2 approvers
                // For Secure Agreement: Second_Approval_Status__c stays 'Pending'
                if (!isSecureAgreement) {
                    Database.update(
                        new Opportunity(Id = oppId, Opportunity_Approval_Status__c = 'Pending Approval'),
                        System.AccessLevel.SYSTEM_MODE
                    );
                }
            }
        } else {
            // All L2 approvers have approved — record is fully approved
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
            if (Approval.isLocked(oppId)) {
                Approval.unlock(oppId);
            }
            ApprovalNotificationSender.sendApprovalOutcome(oppId, opp.Name, opp.OwnerId, 'L2_APPROVED');
            if (isSecureAgreement) {
                sendSAApprovedEmail(oppId);
            } else {
                sendNonSAApprovedEmail(oppId);
            }
        }
    }

    private static void handleRejected(Id oppId, Id actorId, String comments) {
        // Cancel all remaining pending workitems across both L1 and L2
        try {
            recallPendingApprovals(oppId);
        } catch (Exception e) {
            System.debug('DynamicApprovalEngine handleRejected: recall failed — ' + e.getMessage());
        }

        Opportunity opp = [SELECT StageName, OwnerId, Name FROM Opportunity WHERE Id = :oppId LIMIT 1];

        if ('Secure Agreement'.equalsIgnoreCase(opp.StageName)) {
            Database.update(
                new Opportunity(Id = oppId, Second_Approval_Status__c = 'Rejected'),
                System.AccessLevel.SYSTEM_MODE
            );
            String rejectorName  = (String.isNotBlank(UserInfo.getFirstName()) ? UserInfo.getFirstName() + ' ' : '') + UserInfo.getLastName();
            String rejectionDate = System.today().format();
            sendRejectionEmail(oppId, rejectorName, comments, rejectionDate);
        } else {
            Database.update(
                new Opportunity(Id = oppId, Opportunity_Approval_Status__c = 'Rejected'),
                System.AccessLevel.SYSTEM_MODE
            );
        }

        ApprovalNotificationSender.sendApprovalOutcome(oppId, opp.Name, opp.OwnerId, 'REJECTED');
    }

    /*
    ============================================================
    L2 SUBMISSION
    Called automatically from handleApproved / submitLevel2Async
    when all L1 approvers have approved.
    Returns true if L2 was submitted, false if no L2 approvers found.
    ============================================================
    */

    public static void submitLevel2ForOpportunity(Id oppId) {
        submitLevel2Custom(oppId);
    }

    // Returns true if L2 approvers were found and submitted; false if no L2 for this record
    public static Boolean submitLevel2Custom(Id oppId) {

        Opportunity opp;
        try {
            opp = fetchOpportunity(oppId);
        } catch (Exception e) {
            System.debug('DynamicApprovalEngine L2: error fetching opp — ' + e.getMessage());
            return false;
        }

        String   salesType   = getSalesTypeCategory(opp);
        String   amountCat   = getAmountCategory(opp);
        List<Id> approverIds = new List<Id>();

        if (salesType == null) {
            System.debug('DynamicApprovalEngine L2: null salesType for oppId=' + oppId);
            return false;
        }

        try {
            approverIds = resolveApproverIds(opp, salesType, amountCat, 2);
        } catch (Exception e) {
            System.debug('DynamicApprovalEngine L2: error resolving approvers — ' + e.getMessage());
            return false;
        }

        if (approverIds == null || approverIds.isEmpty()) {
            System.debug('DynamicApprovalEngine L2: no L2 approvers for oppId=' + oppId);
            return false;
        }

        try {
            populateRelatedApprovers(oppId, approverIds);

            // Submit one ProcessSubmitRequest per L2 approver — all receive workitems simultaneously
            Boolean isSecureAgreement = 'Secure Agreement'.equalsIgnoreCase(opp.StageName);
            String l2Process = isSecureAgreement ? SA_L2_PROCESS_API_NAME : L2_PROCESS_API_NAME;
            Map<Id, Id> l2WorkitemIds = submitToStandardProcess(oppId, approverIds, l2Process, 'L2');

            // Explicitly lock the record so it stays locked during L2 review.
            // The L1 final approval action may unlock the record; the L2 ProcessSubmitRequest
            // does not always re-lock it in the same transaction, so we enforce it here.
            if (!Approval.isLocked(oppId)) {
                Approval.lock(oppId);
            }

            updatePendingApprovers(oppId, approverIds);

            sendApprovalRequestEmails(approverIds, opp, 'L2', l2WorkitemIds);

            ApprovalNotificationSender.sendApprovalRequestToUsers(approverIds, oppId, opp.Name, 'L2', l2WorkitemIds);

            System.debug('DynamicApprovalEngine L2: submitted for oppId=' + oppId);
            return true;

        } catch (Exception e) {
            System.debug('DynamicApprovalEngine L2: error for oppId=' + oppId + ' — ' + e.getMessage());
            return false;
        }
    }

    /*
    ============================================================
    STANDARD APPROVAL PROCESS SUBMISSION
    One ProcessSubmitRequest per approver — creates parallel
    workitems so all approvers can act simultaneously.
    ============================================================
    */

    // Returns Map<approverId, workitemId> so callers can build direct approve/reject links and notifications
    private static Map<Id, Id> submitToStandardProcess(
        Id       oppId,
        List<Id> approverIds,
        String   processApiName,
        String   levelLabel
    ) {
        List<Approval.ProcessSubmitRequest> submitRequests = new List<Approval.ProcessSubmitRequest>();

        for (Id approverId : approverIds) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(oppId);
            req.setProcessDefinitionNameOrId(processApiName);
            req.setNextApproverIds(new List<Id>{ approverId });
            req.setSkipEntryCriteria(true);
            Boolean isSA     = processApiName.contains('SA');
            Boolean isLevel1 = 'L1'.equalsIgnoreCase(levelLabel);
            String comment;
            if      (!isSA && isLevel1) comment = 'Submitting request for first-level approval.';
            else if (!isSA)             comment = 'Submitting request for second-level approval.';
            else if (isLevel1)          comment = 'Submitting request for first-level additional approval.';
            else                        comment = 'Submitting request for second-level additional approval.';
            req.setComments(comment);
            submitRequests.add(req);
        }

        List<Approval.ProcessResult> results = Approval.process(submitRequests);

        Map<Id, Id>  approverWorkitemIds = new Map<Id, Id>();
        List<String> errors              = new List<String>();

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                List<String> msgs = new List<String>();
                for (Database.Error err : results[i].getErrors()) {
                    msgs.add(err.getMessage());
                }
                errors.add('Approver index ' + i + ': ' + String.join(msgs, ', '));
                continue;
            }
            List<Id> wids = results[i].getNewWorkitemIds();
            if (!wids.isEmpty() && i < approverIds.size()) {
                approverWorkitemIds.put(approverIds[i], wids[0]);
            }
        }

        if (!errors.isEmpty()) {
            throw new AuraHandledException(
                'Approval submission failed — ' + String.join(errors, '; ')
                + '. Please try again or contact your administrator.'
            );
        }

        return approverWorkitemIds;
    }



    private static Boolean isApprovalInProgress(Id oppId, String currentStatus, String secondApprovalStatus, String stageName) {
        Boolean isSecureAgreementStage = 'Secure Agreement'.equalsIgnoreCase(stageName);

        if (isSecureAgreementStage) {
            if ('Pending'.equalsIgnoreCase(secondApprovalStatus) ||
                'L1 Approved'.equalsIgnoreCase(secondApprovalStatus)) return true;
        } else {
            Set<String> alwaysBlockedStatuses = new Set<String>{
                'Submitted',
                'L1 Approved',
                'Pending Approval'
            };
            if (String.isNotBlank(currentStatus)) {
                if (alwaysBlockedStatuses.contains(currentStatus)) return true;
            }
        }

        Integer pendingCount = [
            SELECT COUNT()
            FROM   ProcessInstanceWorkitem
            WHERE  ProcessInstance.TargetObjectId = :oppId
            AND    ProcessInstance.Status         = 'Pending'
        ];
        return pendingCount > 0;
    }

    /*
    ============================================================
    RECALL PENDING APPROVALS
    ============================================================
    */

    private static void recallPendingApprovals(Id recordId) {
        List<ProcessInstance> pending = [
            SELECT Id, (SELECT Id FROM Workitems)
            FROM   ProcessInstance
            WHERE  TargetObjectId = :recordId
            AND    Status         = 'Pending'
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

    // Same pending-workitem lookup as recallPendingApprovals, but rejects rather than recalls
    // the siblings — used specifically when one approver's rejection means the rest should show
    // as "Rejected" in approval history, not "Recalled" (recallPendingApprovals stays as-is for
    // genuine recall scenarios: clean resubmission and manual-recall cascading).
    private static void rejectPendingApprovals(Id recordId) {
        List<ProcessInstance> pending = [
            SELECT Id, (SELECT Id FROM Workitems)
            FROM   ProcessInstance
            WHERE  TargetObjectId = :recordId
            AND    Status         = 'Pending'
        ];
        if (pending.isEmpty()) return;

        List<Approval.ProcessWorkitemRequest> rejections = new List<Approval.ProcessWorkitemRequest>();
        for (ProcessInstance pi : pending) {
            for (ProcessInstanceWorkitem wi : pi.Workitems) {
                Approval.ProcessWorkitemRequest r = new Approval.ProcessWorkitemRequest();
                r.setAction('Reject');
                r.setWorkitemId(wi.Id);
                rejections.add(r);
            }
        }
        if (!rejections.isEmpty()) Approval.process(rejections);
    }

    /*
    ============================================================
    EMAIL NOTIFICATIONS
    ============================================================
    */

    private static void sendApprovalRequestEmails(List<Id> approverIds, Opportunity opp, String level, Map<Id, Id> approverWorkitemIds) {
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Name, Email FROM User WHERE Id IN :approverIds
        ]);

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String oppUrl  = baseUrl + '/' + opp.Id;
        String subject = 'APPROVAL REQUEST - ' + opp.Name;

        List<Messaging.SingleEmailMessage> emails      = new List<Messaging.SingleEmailMessage>();
        List<String>                       toAddresses = new List<String>();

        for (Id approverId : approverIds) {
            User approver = userMap.get(approverId);
            if (approver == null || String.isBlank(approver.Email)) continue;

            Id workitemId = approverWorkitemIds != null ? approverWorkitemIds.get(approverId) : null;
            String approvalUrl = workitemId != null
                ? baseUrl + '/lightning/r/ProcessInstanceWorkitem/' + workitemId + '/view'
                : baseUrl + '/lightning/r/' + opp.Id + '/related/ProcessSteps/view';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ approver.Email });
            email.setSubject(subject);
            email.setHtmlBody(buildApprovalRequestBody(opp, level, oppUrl, approvalUrl));
            email.setSaveAsActivity(false);
            emails.add(email);
            toAddresses.add(approver.Email);
        }

        dispatchEmails(emails);

        if (!toAddresses.isEmpty()) {
            Database.insert(new EmailMessage(
                RelatedToId = opp.Id,
                ToAddress   = String.join(toAddresses, ';'),
                Subject     = subject,
                HtmlBody    = buildApprovalRequestBody(opp, level, oppUrl, oppUrl),
                FromAddress = UserInfo.getUserEmail(),
                FromName    = UserInfo.getName(),
                Status      = '3',
                MessageDate = DateTime.now(),
                Incoming    = false
            ), System.AccessLevel.SYSTEM_MODE);
        }
    }

    // Opportunity_Approval_Status__c = 'Approved' (non-SA stages)
    // If all Delivery/MS/CS = No  → "Approved, ready for Stage 7 – PO & SIGNED CONTRACT"
    // If any Delivery/MS/CS = Yes → "Initial Approval done, move to Stage 6 – Secure Agreement"
    private static void sendNonSAApprovedEmail(Id oppId) {
        Opportunity opp = fetchOpportunity(oppId);
        if (opp.OwnerId == null) return;

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String oppUrl  = baseUrl + '/' + oppId;

        Boolean hasDeliveryMSCS = 'Yes'.equalsIgnoreCase(opp.Delivery_Involved__c)
                                || 'Yes'.equalsIgnoreCase(opp.Managed_Services_Involved__c)
                                || 'Yes'.equalsIgnoreCase(opp.Customer_Services_Involved__c);

        String body = hasDeliveryMSCS
            ? '<p>Hello Team,</p>'
              + '<p>The Initial Approval for the following opportunity has been completed in Salesforce.</p>'
              + '<p>Please update the opportunity to Stage 6 – "Secure Agreement" and submit it for the Additional Approval process, as Delivery/MS/CS is marked as "YES" on this opportunity.</p>'
              + buildOpportunityDetails(opp, oppUrl)
            : '<p>Hello Team,</p>'
              + '<p>Please note that the following opportunity has been approved in Salesforce.<br/>'
              + 'This opportunity is ready to be moved to Stage 7 – "PO &amp; SIGNED CONTRACT".</p>'
              + buildOpportunityDetails(opp, oppUrl);

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(opp.OwnerId);
        email.setWhatId(oppId);
        email.setSubject('OPPORTUNITY APPROVED - ' + opp.Name);
        email.setHtmlBody(body);
        email.setSaveAsActivity(false);
        dispatchEmails(new List<Messaging.SingleEmailMessage>{ email });

        List<User> ownerUser = [SELECT Email FROM User WHERE Id = :opp.OwnerId LIMIT 1];
        if (!ownerUser.isEmpty() && String.isNotBlank(ownerUser[0].Email)) {
            Database.insert(new EmailMessage(
                RelatedToId = oppId,
                ToAddress   = ownerUser[0].Email,
                Subject     = 'OPPORTUNITY APPROVED - ' + opp.Name,
                HtmlBody    = body,
                FromAddress = UserInfo.getUserEmail(),
                FromName    = UserInfo.getName(),
                Status      = '3',
                MessageDate = DateTime.now(),
                Incoming    = false
            ), System.AccessLevel.SYSTEM_MODE);
        }
    }

    // Second_Approval_Status__c = 'Approved' (Secure Agreement stage)
    // Only fires when any Delivery/MS/CS = Yes
    // → "Additional Delivery/MS/CS approval fully completed, ready for Stage 7 – PO & SIGNED CONTRACT"
    private static void sendSAApprovedEmail(Id oppId) {
        Opportunity opp = fetchOpportunity(oppId);

        if (!'Yes'.equalsIgnoreCase(opp.Delivery_Involved__c)
            && !'Yes'.equalsIgnoreCase(opp.Managed_Services_Involved__c)
            && !'Yes'.equalsIgnoreCase(opp.Customer_Services_Involved__c)) return;

        if (opp.OwnerId == null) return;

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String oppUrl  = baseUrl + '/' + oppId;

        String saBody = '<p>Hello Team,</p>'
            + '<p>Please note that the additional Delivery/MS/CS approval has been fully completed in Salesforce.<br/>'
            + 'This opportunity is ready to be moved to Stage 7 – "PO &amp; SIGNED CONTRACT".</p>'
            + buildOpportunityDetails(opp, oppUrl);

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(opp.OwnerId);
        email.setWhatId(oppId);
        email.setSubject('OPPORTUNITY APPROVED - ' + opp.Name);
        email.setHtmlBody(saBody);
        email.setSaveAsActivity(false);
        dispatchEmails(new List<Messaging.SingleEmailMessage>{ email });

        List<User> ownerUser = [SELECT Email FROM User WHERE Id = :opp.OwnerId LIMIT 1];
        if (!ownerUser.isEmpty() && String.isNotBlank(ownerUser[0].Email)) {
            Database.insert(new EmailMessage(
                RelatedToId = oppId,
                ToAddress   = ownerUser[0].Email,
                Subject     = 'OPPORTUNITY APPROVED - ' + opp.Name,
                HtmlBody    = saBody,
                FromAddress = UserInfo.getUserEmail(),
                FromName    = UserInfo.getName(),
                Status      = '3',
                MessageDate = DateTime.now(),
                Incoming    = false
            ), System.AccessLevel.SYSTEM_MODE);
        }
    }

    private static void sendRejectionEmail(Id oppId, String rejectorName, String comments) {
        sendRejectionEmail(oppId, rejectorName, comments, null);
    }

    private static void sendRejectionEmail(Id oppId, String rejectorName, String comments, String rejectionDate) {
        Opportunity opp = fetchOpportunity(oppId);
        if (opp.OwnerId == null) return;

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String oppUrl  = baseUrl + '/' + oppId;

        String rejBody = '<p>Hello Team,</p>'
            + '<p>Please note that the following opportunity has been rejected in Salesforce:</p>'
            + '<p>'
            + 'Opportunity Owner: ' + (opp.Owner   != null ? opp.Owner.Name   : '') + '<br/>'
            + 'Account Name: '      + (opp.Account != null ? opp.Account.Name : '') + '<br/>'
            + 'Opportunity Name: '  + opp.Name + '<br/>'
            + 'Close Date: '        + (opp.CloseDate != null ? String.valueOf(opp.CloseDate) : '') + '<br/>'
            + 'Amount (USD): '      + (opp.Amount != null ? opp.Amount.format() : '') + '<br/>'
            + 'Business Unit: '     + (String.isNotBlank(opp.Business_Unit__c) ? opp.Business_Unit__c : '') + '<br/>'
            + 'Sales Type: '        + (String.isNotBlank(opp.Cross_sell1__c)   ? opp.Cross_sell1__c   : '') + '<br/>'
            + 'Sub-Region: '        + (String.isNotBlank(opp.Sub_Region__c)    ? opp.Sub_Region__c    : '') + '<br/>'
            + 'Link: <a href="' + oppUrl + '">' + oppUrl + '</a>'
            + '</p>'
            + '<p>'
            + 'Rejected By: '        + (String.isNotBlank(rejectorName)  ? rejectorName  : '') + '<br/>'
            + 'Rejection Date: '     + (String.isNotBlank(rejectionDate) ? rejectionDate : '') + '<br/>'
            + 'Rejection Comments: ' + (String.isNotBlank(comments)      ? comments      : '')
            + '</p>';

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(opp.OwnerId);
        email.setWhatId(oppId);
        email.setSubject('OPPORTUNITY REJECTED - ' + opp.Name);
        email.setHtmlBody(rejBody);
        email.setSaveAsActivity(false);
        dispatchEmails(new List<Messaging.SingleEmailMessage>{ email });

        List<User> ownerUser = [SELECT Email FROM User WHERE Id = :opp.OwnerId LIMIT 1];
        if (!ownerUser.isEmpty() && String.isNotBlank(ownerUser[0].Email)) {
            Database.insert(new EmailMessage(
                RelatedToId = oppId,
                ToAddress   = ownerUser[0].Email,
                Subject     = 'OPPORTUNITY REJECTED - ' + opp.Name,
                HtmlBody    = rejBody,
                FromAddress = UserInfo.getUserEmail(),
                FromName    = UserInfo.getName(),
                Status      = '3',
                MessageDate = DateTime.now(),
                Incoming    = false
            ), System.AccessLevel.SYSTEM_MODE);
        }
    }

    private static String buildApprovalRequestBody(Opportunity opp, String level, String oppUrl, String approvalUrl) {
        return '<p>Hi,</p>'
            + '<p>Your approval is required for the following opportunity in Salesforce:</p>'
            + '<p>'
            + 'Opportunity Owner: ' + (opp.Owner   != null ? opp.Owner.Name   : '') + '<br/>'
            + 'Account Name: '      + (opp.Account != null ? opp.Account.Name : '') + '<br/>'
            + 'Opportunity Name: '  + opp.Name + '<br/>'
            + 'Close Date: '        + (opp.CloseDate != null ? String.valueOf(opp.CloseDate) : '') + '<br/>'
            + 'Amount (USD): '      + (opp.Amount != null ? opp.Amount.format() : '') + '<br/>'
            + 'Business Unit: '     + (String.isNotBlank(opp.Business_Unit__c) ? opp.Business_Unit__c : '') + '<br/>'
            + 'Sales Type: '        + (String.isNotBlank(opp.Cross_sell1__c)   ? opp.Cross_sell1__c   : '') + '<br/>'
            + 'Sub-Region: '        + (String.isNotBlank(opp.Sub_Region__c)    ? opp.Sub_Region__c    : '') + '<br/>'
            + 'Link: <a href="' + oppUrl + '">' + oppUrl + '</a>'
            + '</p>'
            + '<br/>'
            + '<a href="' + approvalUrl + '" style="background-color:#003366;color:#ffffff;padding:10px 20px;text-decoration:none;border-radius:4px;font-family:Arial,sans-serif;">'
            + 'Click here to Approve or Reject'
            + '</a>';
    }

    private static String buildOpportunityDetails(Opportunity opp, String oppUrl) {
        return '<p>'
            + 'Opportunity Owner: ' + (opp.Owner   != null ? opp.Owner.Name   : '') + '<br/>'
            + 'Account Name: '      + (opp.Account != null ? opp.Account.Name : '') + '<br/>'
            + 'Opportunity Name: '  + opp.Name + '<br/>'
            + 'Close Date: '        + (opp.CloseDate != null ? String.valueOf(opp.CloseDate) : '') + '<br/>'
            + 'Amount (USD): '      + (opp.Amount != null ? opp.Amount.format() : '') + '<br/>'
            + 'Business Unit: '     + (String.isNotBlank(opp.Business_Unit__c) ? opp.Business_Unit__c : '') + '<br/>'
            + 'Sales Type: '        + (String.isNotBlank(opp.Cross_sell1__c)   ? opp.Cross_sell1__c   : '') + '<br/>'
            + 'Sub-Region: '        + (String.isNotBlank(opp.Sub_Region__c)    ? opp.Sub_Region__c    : '') + '<br/>'
            + 'Link: <a href="' + oppUrl + '">' + oppUrl + '</a>'
            + '</p>';
    }

    private static void dispatchEmails(List<Messaging.SingleEmailMessage> emails) {
        if (emails.isEmpty()) return;
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug(LoggingLevel.ERROR,
                    'DynamicApprovalEngine: email FAILED index ' + i
                    + ' — ' + JSON.serialize(results[i].getErrors()));
            }
        }
    }

    /*
    ============================================================
    OPPORTUNITY & APPROVER RESOLUTION
    ============================================================
    */

    private static Opportunity fetchOpportunity(Id oppId) {
        return [
            SELECT Id,
                   Name,
                   Amount,
                   StageName,
                   CloseDate,
                   OwnerId,
                   Cross_sell1__c,
                   Delivery_Involved__c,
                   Managed_Services_Involved__c,
                   Customer_Services_Involved__c,
                   Hardware_delivery_involved__c,
                   Business_Unit__c,
                   Sub_Region__c,
                   Country__c,
                   Country__r.Name,
                   Account.Name,
                   Owner.Name,
                   Opportunity_Approval_Status__c,
                   Second_Approval_Status__c
            FROM   Opportunity
            WHERE  Id = :oppId
            LIMIT  1
        ];
    }

    private static String getSalesTypeCategory(Opportunity opp) {
        if (String.isBlank(opp.Cross_sell1__c)) return null;
        return opp.Cross_sell1__c.trim();
    }

    private static String getAmountCategory(Opportunity opp) {
        if (opp.Amount == null) return null;
        Decimal amt = opp.Amount;
        return (amt >= 0 && amt < 100000) ? 'Less than 100K' : 'Greater than or equal 100K';
    }

    private static Boolean hasL2Approvers(Id oppId) {
        try {
            Opportunity opp = fetchOpportunity(oppId);
            String salesType = getSalesTypeCategory(opp);
            if (salesType == null) return false;
            String amountCat = getAmountCategory(opp);
            List<Id> approverIds = resolveApproverIds(opp, salesType, amountCat, 2);
            return approverIds != null && !approverIds.isEmpty();
        } catch (Exception e) {
            System.debug('DynamicApprovalEngine hasL2Approvers: ' + e.getMessage());
            return false;
        }
    }

    // Returns true if the given Second_Approval_Status__c value should be treated as fully
    // approved. Accepts both 'Approved' and 'Approved - 2nd' (case-insensitive) so either
    // label satisfies second-approval completion checks throughout this class.
    private static Boolean isSecondApprovalApproved(String status) {
        return String.isNotBlank(status) && SECOND_APPROVAL_APPROVED_VALUES.contains(status.trim().toLowerCase());
    }

    /*
    ============================================================
    RESOLVE APPROVERS — queries Opportunity_Dynamic_Approvals__c
    ============================================================
    */

    private static List<Id> resolveApproverIds(
        Opportunity opp,
        String      salesType,
        String      amountCat,
        Integer     level
    ) {
        List<Opportunity_Dynamic_Approvals__c> allRecords = new List<Opportunity_Dynamic_Approvals__c>();
        try {
            allRecords = [
                SELECT Name,
                       Opportunity_Stage__c,
                       Sales_Type__c,
                       Amount__c,
                       BU__c,
                       Sub_Region__c,
                       Country__c,
                       Account_Name__c,
                       Delivery_Involved__c,
                       X3rd_Party_Involved__c,
                       MS_Involved__c,
                       CS_Involved__c,
                       X3rd_Party_Approver_L1__c,
                       CFO__c,
                       CRO__c,
                       CS_Approver_L1__c,
                       Delivery_Approver_L1__c,
                       MS_Approver_L1__c,
                       PM_Approver_L1__c,
                       Sales_GM_L1__c,
                       X3rd_Party_Approver_L2__c,
                       CS_Approver_L2__c,
                       Delivery_Approver_L2__c,
                       MS_Approver_L2__c,
                       PM_L2__c
                FROM   Opportunity_Dynamic_Approvals__c
            ];
        } catch (Exception e) {
            System.debug('DynamicApprovalEngine resolveApproverIds (level=' + level + '): SOQL failed — ' + e.getMessage());
            return new List<Id>();
        }
        if (allRecords.isEmpty()) return new List<Id>();

        String approvalStage = STAGE_4_AND_EARLIER.contains(opp.StageName)
            ? 'Develop Solution'
            : opp.StageName;

        String oppSubRegion = String.isNotBlank(opp.Sub_Region__c) ? opp.Sub_Region__c.trim() : '';
        Set<String> oppBUSet = new Set<String>();
        if (String.isNotBlank(opp.Business_Unit__c)) {
            for (String buVal : opp.Business_Unit__c.split('[,;]')) {
                String trimmed = buVal.trim().toLowerCase();
                if (String.isNotBlank(trimmed)) oppBUSet.add(trimmed);
            }
        }

        String oppCountry = (opp.Country__r != null && String.isNotBlank(opp.Country__r.Name))
            ? opp.Country__r.Name.trim().toLowerCase() : '';
        String oppAccount = (opp.Account != null && String.isNotBlank(opp.Account.Name))
            ? opp.Account.Name.trim().toLowerCase() : '';

        List<Opportunity_Dynamic_Approvals__c> specificMatches = new List<Opportunity_Dynamic_Approvals__c>();
        List<Opportunity_Dynamic_Approvals__c> allMatches      = new List<Opportunity_Dynamic_Approvals__c>();

        for (Opportunity_Dynamic_Approvals__c rec : allRecords) {
            if (String.isBlank(rec.Opportunity_Stage__c) || !rec.Opportunity_Stage__c.equalsIgnoreCase(approvalStage)) continue;
            if (String.isBlank(rec.Sales_Type__c)        || !rec.Sales_Type__c.equalsIgnoreCase(salesType))            continue;
            if (String.isBlank(rec.Amount__c)            || !rec.Amount__c.equalsIgnoreCase(amountCat))                continue;

            if (String.isNotBlank(rec.BU__c) && !rec.BU__c.equalsIgnoreCase('All')) {
                if (!oppBUSet.contains(rec.BU__c.trim().toLowerCase())) continue;
            }

            if (!fieldMatches(rec.Delivery_Involved__c,   opp.Delivery_Involved__c))          continue;
            if (!fieldMatches(rec.X3rd_Party_Involved__c, opp.Hardware_delivery_involved__c)) continue;
            if (!fieldMatches(rec.MS_Involved__c,         opp.Managed_Services_Involved__c))  continue;
            if (!fieldMatches(rec.CS_Involved__c,         opp.Customer_Services_Involved__c)) continue;

            // This first pass is for Country/Account-specific override rules only — a rule with
            // neither field set is generic and must not compete with (or be merged alongside)
            // a matching override. Generic rules are only considered in the fallback pass below.
            Boolean isCountryOrAccountSpecific = rec.Country__c != null || String.isNotBlank(rec.Account_Name__c);
            if (!isCountryOrAccountSpecific) continue;

            if (rec.Country__c != null) {
                if (!String.valueOf(rec.Country__c).trim().toLowerCase().equals(oppCountry)) continue;
            }
            if (String.isNotBlank(rec.Account_Name__c)) {
                if (!rec.Account_Name__c.trim().toLowerCase().equals(oppAccount)) continue;
            }

            if (String.isBlank(rec.Sub_Region__c) || rec.Sub_Region__c.equalsIgnoreCase('All')) {
                allMatches.add(rec);
            } else if (rec.Sub_Region__c.equalsIgnoreCase(oppSubRegion)) {
                specificMatches.add(rec);
            }
        }

        // Fallback to generic (non-Country/Account-specific) rules only if no override matched
        if (specificMatches.isEmpty() && allMatches.isEmpty()) {
            for (Opportunity_Dynamic_Approvals__c rec : allRecords) {
                if (String.isBlank(rec.Opportunity_Stage__c) || !rec.Opportunity_Stage__c.equalsIgnoreCase(approvalStage)) continue;
                if (String.isBlank(rec.Sales_Type__c)        || !rec.Sales_Type__c.equalsIgnoreCase(salesType))            continue;
                if (String.isBlank(rec.Amount__c)            || !rec.Amount__c.equalsIgnoreCase(amountCat))                continue;

                if (String.isNotBlank(rec.BU__c) && !rec.BU__c.equalsIgnoreCase('All')) {
                    if (!oppBUSet.contains(rec.BU__c.trim().toLowerCase())) continue;
                }

                if (!fieldMatches(rec.Delivery_Involved__c,   opp.Delivery_Involved__c))          continue;
                if (!fieldMatches(rec.X3rd_Party_Involved__c, opp.Hardware_delivery_involved__c)) continue;
                if (!fieldMatches(rec.MS_Involved__c,         opp.Managed_Services_Involved__c))  continue;
                if (!fieldMatches(rec.CS_Involved__c,         opp.Customer_Services_Involved__c)) continue;

                if (rec.Country__c != null || String.isNotBlank(rec.Account_Name__c)) continue;

                if (String.isBlank(rec.Sub_Region__c) || rec.Sub_Region__c.equalsIgnoreCase('All')) {
                    allMatches.add(rec);
                } else if (rec.Sub_Region__c.equalsIgnoreCase(oppSubRegion)) {
                    specificMatches.add(rec);
                }
            }
        }

        List<Opportunity_Dynamic_Approvals__c> matchedRecords = new List<Opportunity_Dynamic_Approvals__c>();
        if (!specificMatches.isEmpty()) {
            matchedRecords.addAll(specificMatches);
            matchedRecords.addAll(allMatches);
        } else if (!allMatches.isEmpty()) {
            matchedRecords.addAll(allMatches);
        }

        if (matchedRecords.isEmpty()) return new List<Id>();

        List<String> matchedEmails = new List<String>();
        Set<String>  seenEmails    = new Set<String>();

        for (Opportunity_Dynamic_Approvals__c matched : matchedRecords) {
            if (level == 1) {
                collectEmails(matchedEmails, seenEmails, matched.X3rd_Party_Approver_L1__c);
                collectEmails(matchedEmails, seenEmails, matched.CS_Approver_L1__c);
                collectEmails(matchedEmails, seenEmails, matched.Delivery_Approver_L1__c);
                collectEmails(matchedEmails, seenEmails, matched.MS_Approver_L1__c);
                collectEmails(matchedEmails, seenEmails, matched.PM_Approver_L1__c);
                collectEmails(matchedEmails, seenEmails, matched.Sales_GM_L1__c);
            } else {
                collectEmails(matchedEmails, seenEmails, matched.X3rd_Party_Approver_L2__c);
                collectEmails(matchedEmails, seenEmails, matched.CS_Approver_L2__c);
                collectEmails(matchedEmails, seenEmails, matched.Delivery_Approver_L2__c);
                collectEmails(matchedEmails, seenEmails, matched.MS_Approver_L2__c);
                collectEmails(matchedEmails, seenEmails, matched.PM_L2__c);
                if (!'Secure Agreement'.equalsIgnoreCase(opp.StageName)) {
                    collectEmails(matchedEmails, seenEmails, matched.CFO__c);
                    collectEmails(matchedEmails, seenEmails, matched.CRO__c);
                }
            }
        }

        if (matchedEmails.isEmpty()) return new List<Id>();

        Map<String, User> usersByEmail = new Map<String, User>();
        for (User u : [
            SELECT Id, Email FROM User WHERE Email IN :matchedEmails AND IsActive = true
        ]) {
            usersByEmail.put(u.Email.toLowerCase(), u);
        }

        List<Id> approverIds  = new List<Id>();
        Set<Id>  addedUserIds = new Set<Id>();
        for (String email : matchedEmails) {
            User u = usersByEmail.get(email);
            if (u != null && addedUserIds.add(u.Id)) approverIds.add(u.Id);
        }

        return approverIds;
    }

    /*
    ============================================================
    PRE-APPROVAL VALIDATION
    Returns a message string if validation fails, null if all pass.
    Only result.message is set by callers — status is never set —
    so no status label appears above the message in the UI.
    ============================================================
    */
    @TestVisible
    private static String validatePreApprovalConditions(Opportunity opp) {
        if (opp == null) {
            return 'Opportunity Approval - No Opportunity was found';
        }
        if (String.isBlank(opp.Cross_sell1__c)) {
            return 'Opportunity Approval - Sales Type is not selected.';
        }
        if (String.isBlank(opp.Sub_Region__c)) {
            return 'Opportunity Approval - Sub Region field should be filled';
        }
        if (String.isBlank(opp.Hardware_delivery_involved__c)) {
            return 'Opportunity Approval – "3rd party HW/SW, HW (proprietary)" field is mandatory. Please select Yes/No';
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
        if (BLOCKED_APPROVAL_STAGES.contains(opp.StageName)) {
            return 'No applicable approval flow at this stage';
        }
        return null;
    }

    private static Boolean fieldMatches(String metaVal, String oppVal) {
        if (String.isBlank(metaVal)) return true;
        return metaVal.trim().equalsIgnoreCase(oppVal != null ? oppVal.trim() : '');
    }

    private static void collectEmails(List<String> emails, Set<String> seen, String emailField) {
        if (String.isBlank(emailField)) return;
        for (String em : emailField.split(';')) {
            String normalised = em.trim().toLowerCase();
            if (String.isNotBlank(normalised) && seen.add(normalised)) emails.add(normalised);
        }
    }

    private static void updatePendingApprovers(Id oppId, List<Id> approverIds) {
        List<String> approverNames = new List<String>();
        for (User u : [SELECT FirstName, LastName FROM User WHERE Id IN :approverIds ORDER BY Name]) {
            approverNames.add((String.isNotBlank(u.FirstName) ? u.FirstName + ' ' : '') + u.LastName);
        }
        Database.update(
            new Opportunity(Id = oppId, Pending_Approvers__c = String.join(approverNames, ';')),
            System.AccessLevel.SYSTEM_MODE
        );
    }

    private static Map<String, Id> processDefinitionIdByName = new Map<String, Id>();

    // Resolves a ProcessDefinition Id by DeveloperName without any relationship traversal,
    // so callers can filter ProcessInstance directly on ProcessDefinitionId — filtering
    // ProcessInstance by ProcessDefinition.DeveloperName is rejected as an illegal filter
    // against this org's real data volume even though it passes in test context.
    private static Id getProcessDefinitionId(String processApiName) {
        if (!processDefinitionIdByName.containsKey(processApiName)) {
            List<ProcessDefinition> defs = [SELECT Id FROM ProcessDefinition WHERE DeveloperName = :processApiName LIMIT 1];
            processDefinitionIdByName.put(processApiName, defs.isEmpty() ? null : defs[0].Id);
        }
        return processDefinitionIdByName.get(processApiName);
    }

    // True if any ProcessInstance for this specific level's process is still Pending for this
    // Opportunity — used to detect that other approvers at the same level haven't acted yet.
    private static Boolean hasPendingSiblings(Id oppId, String processApiName) {
        Id processDefId = getProcessDefinitionId(processApiName);
        if (processDefId == null) return false;
        List<ProcessInstance> pendingInstances = [
            SELECT Id
            FROM   ProcessInstance
            WHERE  TargetObjectId      = :oppId
            AND    Status              = 'Pending'
            AND    ProcessDefinitionId = :processDefId
        ];
        return !pendingInstances.isEmpty();
    }

    // Recomputes Pending_Approvers__c from whatever ProcessInstanceWorkitems are still Pending
    // right now, and clears it once nothing is left pending. Keeps the field in sync as each
    // approver acts and as the record reaches a terminal (approved/rejected/recalled) state.
    private static void refreshPendingApprovers(Id oppId) {
        List<ProcessInstanceWorkitem> pending = [
            SELECT CreatedDate, Actor.FirstName, Actor.LastName
            FROM   ProcessInstanceWorkitem
            WHERE  ProcessInstance.TargetObjectId = :oppId
            AND    ProcessInstance.Status         = 'Pending'
        ];
        List<String> names = new List<String>();
        for (ProcessInstanceWorkitem wi : pending) {
            if (wi.Actor != null) {
                names.add((String.isNotBlank(wi.Actor.FirstName) ? wi.Actor.FirstName + ' ' : '') + wi.Actor.LastName);
            }
        }
        Opportunity oppToUpdate = new Opportunity(
            Id = oppId,
            Pending_Approvers__c = names.isEmpty() ? null : String.join(names, ';')
        );
        // Matches cls_OpportunityApprovalHandler.fillPendingApprovers' original Submitted_Date__c
        // logic: while at least one workitem is Pending, set it to that workitem's CreatedDate;
        // once nothing is pending, leave it untouched (frozen), not cleared.
        if (!pending.isEmpty()) {
            oppToUpdate.Submitted_Date__c = pending[0].CreatedDate;
        }
        Database.update(oppToUpdate, System.AccessLevel.SYSTEM_MODE);
    }

    private static void populateRelatedApprovers(Id oppId, List<Id> approverIds) {
        List<Related_Approver__c> existing = [
            SELECT Id FROM Related_Approver__c WHERE Opportunity__c = :oppId LIMIT 1
        ];
        Boolean isNew = existing.isEmpty();

        Related_Approver__c rec;
        if (isNew) {
            String oppName = [SELECT Name FROM Opportunity WHERE Id = :oppId LIMIT 1].Name;
            // Related_Approver__c.Name is a standard Text field limited to 80 characters.
            // Opportunity names can exceed that length, which previously caused
            // "STRING_TOO_LONG" DML failures on insert. Truncate defensively so the
            // record can still be created even when the Opportunity name is long.
            if (String.isNotBlank(oppName) && oppName.length() > 80) {
                oppName = oppName.substring(0, 80);
            }
            rec = new Related_Approver__c(Name = oppName, Opportunity__c = oppId);
        } else {
            rec = existing[0];
        }

        rec.Approver_1__c  = null; rec.Approver_2__c  = null; rec.Approver_3__c  = null;
        rec.Approver_4__c  = null; rec.Approver_5__c  = null; rec.Approver_6__c  = null;
        rec.Approver_7__c  = null; rec.Approver_8__c  = null; rec.Approver_9__c  = null;
        rec.Approver_10__c = null; rec.Approver_11__c = null; rec.Approver_12__c = null;
        rec.Approver_13__c = null; rec.Approver_14__c = null; rec.Approver_15__c = null;
        rec.Approver_16__c = null; rec.Approver_17__c = null; rec.Approver_18__c = null;
        rec.Approver_19__c = null; rec.Approver_20__c = null; rec.Approver_21__c = null;
        rec.Approver_22__c = null; rec.Approver_23__c = null; rec.Approver_24__c = null;
        rec.Approver_25__c = null;

        Integer idx = 1;
        for (Id uid : approverIds) {
            if      (idx == 1)  rec.Approver_1__c  = uid;
            else if (idx == 2)  rec.Approver_2__c  = uid;
            else if (idx == 3)  rec.Approver_3__c  = uid;
            else if (idx == 4)  rec.Approver_4__c  = uid;
            else if (idx == 5)  rec.Approver_5__c  = uid;
            else if (idx == 6)  rec.Approver_6__c  = uid;
            else if (idx == 7)  rec.Approver_7__c  = uid;
            else if (idx == 8)  rec.Approver_8__c  = uid;
            else if (idx == 9)  rec.Approver_9__c  = uid;
            else if (idx == 10) rec.Approver_10__c = uid;
            else if (idx == 11) rec.Approver_11__c = uid;
            else if (idx == 12) rec.Approver_12__c = uid;
            else if (idx == 13) rec.Approver_13__c = uid;
            else if (idx == 14) rec.Approver_14__c = uid;
            else if (idx == 15) rec.Approver_15__c = uid;
            else if (idx == 16) rec.Approver_16__c = uid;
            else if (idx == 17) rec.Approver_17__c = uid;
            else if (idx == 18) rec.Approver_18__c = uid;
            else if (idx == 19) rec.Approver_19__c = uid;
            else if (idx == 20) rec.Approver_20__c = uid;
            else if (idx == 21) rec.Approver_21__c = uid;
            else if (idx == 22) rec.Approver_22__c = uid;
            else if (idx == 23) rec.Approver_23__c = uid;
            else if (idx == 24) rec.Approver_24__c = uid;
            else if (idx == 25) rec.Approver_25__c = uid;
            idx++;
        }

        if (isNew) { Database.insert(rec, System.AccessLevel.SYSTEM_MODE); }
        else        { Database.update(rec, System.AccessLevel.SYSTEM_MODE); }
    }

    /*
    ============================================================
    STAGE CHANGE VALIDATION
    Called from OpportunityTrigger (before update context).
    Blocks or warns when stage advances without required approvals.
    ============================================================
    */
    public static void validateStageChange(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        for (Opportunity newOpp : newOpps) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            if (oldOpp == null || CLOSED_LOST_STAGES.contains(newOpp.StageName)) continue;

            Integer newStageNum = STAGE_NUMBERS.get(newOpp.StageName);
            Integer oldStageNum = STAGE_NUMBERS.get(oldOpp.StageName);
            if (newStageNum == null || oldStageNum == null || newStageNum <= oldStageNum) continue;

            // Stage ≥ 5 advanced without first approval → hard block
            if (newStageNum >= 5) {
                String approvalStatus = newOpp.Opportunity_Approval_Status__c;
                if (String.isBlank(approvalStatus) || !approvalStatus.containsIgnoreCase('Approved')) {
                    newOpp.addError('Cannot move to the stage ' + newOpp.StageName + ' if the first approval flow is not approved.');
                    continue;
                }
            }

            // Stage ≥ 7 advanced without second approval (when Delivery/MS/CS involved) → hard block
            if (newStageNum >= 7) {
                Boolean needsSecondApproval = 'Yes'.equalsIgnoreCase(newOpp.Delivery_Involved__c)         ||
                                              'Yes'.equalsIgnoreCase(newOpp.Managed_Services_Involved__c) ||
                                              'Yes'.equalsIgnoreCase(newOpp.Customer_Services_Involved__c);
                if (needsSecondApproval && !isSecondApprovalApproved(newOpp.Second_Approval_Status__c)) {
                    newOpp.addError('Cannot move to the stage ' + newOpp.StageName + ' if the second approval flow is not completed.');
                }
            }
        }
    }

    private static void fireToastEvent(String key, String message, String title, String mode, String variant) {
        ToastEvent__e toastEvent = new ToastEvent__e();
        toastEvent.Message__c = message;
        toastEvent.Key__c     = key;
        toastEvent.Mode__c    = mode;
        toastEvent.Title__c   = title;
        toastEvent.Variant__c = variant;
        EventBus.publish(toastEvent);
    }
}