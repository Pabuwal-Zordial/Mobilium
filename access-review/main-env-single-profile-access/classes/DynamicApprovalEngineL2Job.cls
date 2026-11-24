public class DynamicApprovalEngineL2Job implements Queueable {

    private Set<Id> oppIds;

    public DynamicApprovalEngineL2Job(Set<Id> oppIds) {
        this.oppIds = oppIds;
    }

    public void execute(QueueableContext ctx) {
        for (Id oppId : oppIds) {
            DynamicApprovalEngine.submitLevel2ForOpportunity(oppId);
        }
    }
}