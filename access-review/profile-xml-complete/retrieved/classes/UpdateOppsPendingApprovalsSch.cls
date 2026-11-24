global with sharing class UpdateOppsPendingApprovalsSch implements Schedulable {
    global void execute(SchedulableContext sc) {
        ID BatchId = Database.executeBatch(new UpdateOppsPendingApprovalsBatch(), 10);
    }
}