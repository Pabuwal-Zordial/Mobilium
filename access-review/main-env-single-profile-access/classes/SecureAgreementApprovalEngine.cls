public without sharing class SecureAgreementApprovalEngine {

    public class ApprovalRequest {
        @InvocableVariable(required=true)
        public Id opportunityId;
    }

    public class ApprovalResult {
        @InvocableVariable public String status;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Submit Secure Agreement Approval')
    public static List<ApprovalResult> submit(List<ApprovalRequest> requests) {
        List<DynamicApprovalEngine.ApprovalRequest> engineRequests = new List<DynamicApprovalEngine.ApprovalRequest>();
        for (ApprovalRequest req : requests) {
            DynamicApprovalEngine.ApprovalRequest r = new DynamicApprovalEngine.ApprovalRequest();
            r.opportunityId = req.opportunityId;
            engineRequests.add(r);
        }

        List<DynamicApprovalEngine.ApprovalResult> engineResults = DynamicApprovalEngine.submitSAApproval(engineRequests);

        List<ApprovalResult> results = new List<ApprovalResult>();
        for (DynamicApprovalEngine.ApprovalResult er : engineResults) {
            ApprovalResult res = new ApprovalResult();
            res.status  = er.status;
            res.message = er.message;
            results.add(res);
        }
        return results;
    }
}