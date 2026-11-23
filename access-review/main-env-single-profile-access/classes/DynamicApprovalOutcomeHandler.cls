public without sharing class DynamicApprovalOutcomeHandler {

    // Called from the standard approval process Final Approval Action / Rejection Action.
    // outcome: 'Approved' or 'Rejected'
    // level:   'L1' or 'L2'
    @InvocableMethod(label='Handle Dynamic Approval Outcome')
    public static void handleApprovalOutcome(List<DynamicApprovalEngine.ApprovalOutcomeRequest> requests) {
        DynamicApprovalEngine.handleApprovalOutcome(requests);
    }
}