public class DIAB_MB_BatchShareTimecardsToNewPM implements Database.Batchable<Id>, Database.Stateful {

    // START
    public Iterable<Id> start(Database.BatchableContext bc) {
        System.debug('=== START METHOD ENTERED ===');

        Map<Id, DateTime> latestChangeDate = new Map<Id, DateTime>();
        Map<Id, String> newPmByProject = new Map<Id, String>();

        List<pse__Proj__History> historyRows = [
            SELECT Id, ParentId, Field, OldValue, NewValue, CreatedDate
            FROM pse__Proj__History
            WHERE Field = 'pse__Project_Manager__c'
            ORDER BY CreatedDate DESC
        ];

        System.debug('History Records Retrieved: ' + historyRows.size());

        // Identify latest change per project
        for (pse__Proj__History ph : historyRows) {
            if (!latestChangeDate.containsKey(ph.ParentId) || ph.CreatedDate > latestChangeDate.get(ph.ParentId)) {
                latestChangeDate.put(ph.ParentId, ph.CreatedDate);
                if (ph.OldValue != ph.NewValue) {
                    newPmByProject.put(ph.ParentId, (String)ph.NewValue);
                }
            }
        }

        System.debug('Projects With Updated PMs: ' + newPmByProject.keySet());

        // Return as Iterable<Id>
        return newPmByProject.keySet();
    }

    // EXECUTE
    public void execute(Database.BatchableContext bc, List<Id> scope) {
        if (scope.isEmpty()) return;

        System.debug('Processing Projects: ' + scope);
        system.debug('Unique: ' + scope.size());

        // Pull timecards for these projects
        List<pse__Timecard_Header__c> timecards = [
            SELECT Id,
                   pse__Project__c,
                   pse__Approver__c,
                   pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__c
            FROM pse__Timecard_Header__c
            WHERE pse__Project__c IN :scope
        ];
            system.debug( timecards);
                    system.debug( timecards.size());

        List<pse__Timecard_Header__Share> shares = new List<pse__Timecard_Header__Share>();

        for (pse__Timecard_Header__c tc : timecards) {
            Id newPMUser = tc.pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__c;

            if (newPMUser == null) continue;
            if (tc.pse__Approver__c == newPMUser) continue;

            shares.add(new pse__Timecard_Header__Share(
                ParentId      = tc.Id,
                UserOrGroupId = newPMUser,
                AccessLevel   = 'Read',
                RowCause      = Schema.pse__Timecard_Header__Share.RowCause.Manual
            ));
        }

        if (!shares.isEmpty()) {
            Database.insert(shares, false);
            system.debug(shares);
            system.debug(shares.size());
        }
    }

    // FINISH
    public void finish(Database.BatchableContext bc) {
        System.debug('=== FINISH METHOD: PM Timecard Sharing Batch Completed ===');
    }
}