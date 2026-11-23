public without sharing class DynamicApprovalReassignmentHandler {

    public class ReassignmentRequest {
        @InvocableVariable(required=true) public Id opportunityId;
        @InvocableVariable               public Id newAssigneeId;
    }

    @InvocableMethod(label='Send Reassignment Approval Email')
    public static List<DynamicApprovalEngine.ApprovalResult> sendReassignmentApprovalEmails(List<ReassignmentRequest> requests) {
        List<DynamicApprovalEngine.ReassignmentRequest> engineRequests = new List<DynamicApprovalEngine.ReassignmentRequest>();
        for (ReassignmentRequest req : requests) {
            DynamicApprovalEngine.ReassignmentRequest er = new DynamicApprovalEngine.ReassignmentRequest();
            er.opportunityId = req.opportunityId;
            er.newAssigneeId = req.newAssigneeId;
            engineRequests.add(er);
        }
        return DynamicApprovalEngine.sendReassignmentApprovalEmails(engineRequests);
    }
}