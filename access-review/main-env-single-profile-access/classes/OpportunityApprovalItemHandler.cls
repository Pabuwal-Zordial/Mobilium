public without sharing class OpportunityApprovalItemHandler {

    public static void handleStatusChange(
        List<Opportunity_Approval_Item__c> newItems,
        Map<Id, Opportunity_Approval_Item__c> oldMap
    ) {
        Map<Id, String>   rejectedOppToLevel    = new Map<Id, String>();
        Map<Id, Id>       rejectedOppToApprover = new Map<Id, Id>();
        Map<Id, String>   rejectedOppToComments = new Map<Id, String>();
        Map<Id, DateTime> rejectedOppToDate     = new Map<Id, DateTime>();
        Map<Id, Id>       rejectedOppToItemId   = new Map<Id, Id>();
        Set<Id>           approvedCheckOpps     = new Set<Id>();

        for (Opportunity_Approval_Item__c item : newItems) {
            Opportunity_Approval_Item__c oldItem = oldMap.get(item.Id);
            if (oldItem.Status__c != 'Pending') continue;

            if (item.Status__c == 'Rejected') {
                if (!rejectedOppToLevel.containsKey(item.Opportunity__c)) {
                    rejectedOppToLevel.put(item.Opportunity__c,    item.Level__c);
                    rejectedOppToApprover.put(item.Opportunity__c, item.Approver__c);
                    rejectedOppToComments.put(item.Opportunity__c, item.Comments__c);
                    rejectedOppToDate.put(item.Opportunity__c,     item.Action_Date__c);
                    rejectedOppToItemId.put(item.Opportunity__c,   item.Id);
                }
            } else if (item.Status__c == 'Approved') {
                approvedCheckOpps.add(item.Opportunity__c);
            }
        }

        if (!rejectedOppToLevel.isEmpty()) {
            handleRejections(rejectedOppToLevel, rejectedOppToApprover, rejectedOppToComments, rejectedOppToDate, rejectedOppToItemId);
        }
        if (!approvedCheckOpps.isEmpty()) {
            checkAllApproved(approvedCheckOpps);
        }
    }

    // -------------------------------------------------------

    private static void handleRejections(
        Map<Id, String>   rejectedOppToLevel,
        Map<Id, Id>       rejectedOppToApprover,
        Map<Id, String>   rejectedOppToComments,
        Map<Id, DateTime> rejectedOppToDate,
        Map<Id, Id>       rejectedOppToItemId
    ) {
        List<Opportunity_Approval_Item__c> toCancel = new List<Opportunity_Approval_Item__c>();
        for (Opportunity_Approval_Item__c item : [
            SELECT Id
            FROM   Opportunity_Approval_Item__c
            WHERE  Opportunity__c IN :rejectedOppToLevel.keySet()
            AND    Status__c      = 'Pending'
        ]) {
            item.Status__c = 'Cancelled';
            toCancel.add(item);
        }
        if (!toCancel.isEmpty()) {
            Database.update(toCancel, System.AccessLevel.SYSTEM_MODE);
        }

        List<Opportunity> toUpdate = new List<Opportunity>();
        for (Id oppId : rejectedOppToLevel.keySet()) {
            toUpdate.add(new Opportunity(
                Id = oppId,
                Opportunity_Approval_Status__c = rejectedOppToLevel.get(oppId) + ' Rejected'
            ));
        }
        Database.update(toUpdate, System.AccessLevel.SYSTEM_MODE);

        Set<Id> approverIds = new Set<Id>(rejectedOppToApprover.values());
        Map<Id, String> approverNames = new Map<Id, String>();
        for (User u : [SELECT Id, Name FROM User WHERE Id IN :approverIds]) {
            approverNames.put(u.Id, u.Name);
        }

        for (Id oppId : rejectedOppToLevel.keySet()) {
            sendRejectionEmail(
                oppId,
                rejectedOppToItemId.get(oppId),
                approverNames.get(rejectedOppToApprover.get(oppId)),
                rejectedOppToDate.get(oppId),
                rejectedOppToComments.get(oppId)
            );
        }
    }

    // -------------------------------------------------------

    private static void checkAllApproved(Set<Id> oppIds) {
        Map<Id, Map<String, Integer>> pendingByLevel  = new Map<Id, Map<String, Integer>>();
        Map<Id, Map<String, Integer>> approvedByLevel = new Map<Id, Map<String, Integer>>();

        for (AggregateResult ar : [
            SELECT Opportunity__c oppId,
                   Level__c       level,
                   Status__c      status,
                   COUNT(Id)      cnt
            FROM   Opportunity_Approval_Item__c
            WHERE  Opportunity__c IN :oppIds
            AND    Status__c      IN ('Pending', 'Approved')
            GROUP BY Opportunity__c, Level__c, Status__c
        ]) {
            Id      oppId  = (Id)      ar.get('oppId');
            String  level  = (String)  ar.get('level');
            String  status = (String)  ar.get('status');
            Integer cnt    = (Integer) ar.get('cnt');

            if (!pendingByLevel.containsKey(oppId)) {
                pendingByLevel.put(oppId,  new Map<String, Integer>());
                approvedByLevel.put(oppId, new Map<String, Integer>());
            }
            if (status == 'Pending') {
                pendingByLevel.get(oppId).put(level, cnt);
            } else {
                approvedByLevel.get(oppId).put(level, cnt);
            }
        }

        List<Opportunity> oppsToUpdate    = new List<Opportunity>();
        List<Id>          triggerL2       = new List<Id>();
        List<Id>          finalApprovedIds = new List<Id>();

        for (Id oppId : oppIds) {
            Map<String, Integer> pending  = pendingByLevel.get(oppId);
            Map<String, Integer> approved = approvedByLevel.get(oppId);
            if (pending  == null) pending  = new Map<String, Integer>();
            if (approved == null) approved = new Map<String, Integer>();

            Integer l1Pend = pending.containsKey('L1')  ? pending.get('L1')  : 0;
            Integer l1Appr = approved.containsKey('L1') ? approved.get('L1') : 0;
            Boolean noL2   = !pending.containsKey('L2') && !approved.containsKey('L2');

            if (l1Pend == 0 && l1Appr > 0 && noL2) {
                oppsToUpdate.add(new Opportunity(
                    Id = oppId,
                    Opportunity_Approval_Status__c = 'L1 Approved'
                ));
                triggerL2.add(oppId);
            }

            Integer l2Pend = pending.containsKey('L2')  ? pending.get('L2')  : 0;
            Integer l2Appr = approved.containsKey('L2') ? approved.get('L2') : 0;

            if (l2Pend == 0 && l2Appr > 0) {
                oppsToUpdate.add(new Opportunity(
                    Id = oppId,
                    Opportunity_Approval_Status__c = 'L2 Approved'
                ));
                finalApprovedIds.add(oppId);
            }
        }

        if (!oppsToUpdate.isEmpty()) {
            Database.update(oppsToUpdate, System.AccessLevel.SYSTEM_MODE);
        }

        // Collect all opps that need an approved notification and look up one item Id each
        Set<Id> notifyOpps = new Set<Id>();
        notifyOpps.addAll(triggerL2);
        notifyOpps.addAll(finalApprovedIds);

        Map<Id, Id> oppToApprovedItemId = new Map<Id, Id>();
        if (!notifyOpps.isEmpty()) {
            for (Opportunity_Approval_Item__c item : [
                SELECT Id, Opportunity__c
                FROM   Opportunity_Approval_Item__c
                WHERE  Opportunity__c IN :notifyOpps
                AND    Status__c      = 'Approved'
                ORDER BY LastModifiedDate DESC
            ]) {
                if (!oppToApprovedItemId.containsKey(item.Opportunity__c)) {
                    oppToApprovedItemId.put(item.Opportunity__c, item.Id);
                }
            }
        }

        for (Id oppId : triggerL2) {
            DynamicApprovalEngine.submitLevel2Custom(oppId);
        }
        for (Id oppId : triggerL2) {
            sendApprovedEmail(oppId, oppToApprovedItemId.get(oppId), true);
        }
        for (Id oppId : finalApprovedIds) {
            sendApprovedEmail(oppId, oppToApprovedItemId.get(oppId), false);
        }
    }

    private static final String ALWAYS_NOTIFY_EMAIL = 'nagasailakshmi.satti@forsysinc.com';

    // -------------------------------------------------------
    // Rejection email

    private static void sendRejectionEmail(
        Id oppId, Id itemId, String approverName, DateTime rejectionDate, String comments
    ) {
        Opportunity opp = fetchOpp(oppId);
        List<User> owners = [SELECT Email, Name FROM User WHERE Id = :opp.OwnerId LIMIT 1];
        if (owners.isEmpty() || String.isBlank(owners[0].Email)) return;

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String oppUrl  = baseUrl + '/' + oppId;

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ owners[0].Email });
        email.setCcAddresses(new List<String>{ ALWAYS_NOTIFY_EMAIL });
        email.setSubject('OPPORTUNITY REJECTED - ' + opp.Name);
        email.setHtmlBody(
            '<p>Hello Team,</p>'
            + '<p>Please note the following opportunity has been rejected in Salesforce:</p>'
            + '<table border="1" cellpadding="8" cellspacing="0" style="border-collapse:collapse;font-family:Arial,sans-serif;font-size:14px;">'
            + '<tr><td><b>Opportunity Owner</b></td><td>'  + (opp.Owner   != null ? opp.Owner.Name   : '') + '</td></tr>'
            + '<tr><td><b>Account Name</b></td><td>'       + (opp.Account != null ? opp.Account.Name : '') + '</td></tr>'
            + '<tr><td><b>Opportunity Name</b></td><td>'   + opp.Name + '</td></tr>'
            + '<tr><td><b>Close Date</b></td><td>'         + (opp.CloseDate != null ? String.valueOf(opp.CloseDate) : '') + '</td></tr>'
            + '<tr><td><b>TCV / Amount (USD)</b></td><td>' + (opp.Amount != null ? opp.Amount.format() : '') + '</td></tr>'
            + '<tr><td><b>ACV (USD)</b></td><td></td></tr>'
            + '<tr><td><b>Business Unit</b></td><td>'      + (String.isNotBlank(opp.Business_Unit__c) ? opp.Business_Unit__c : '') + '</td></tr>'
            + '<tr><td><b>Sales Type</b></td><td>'         + (String.isNotBlank(opp.Cross_sell1__c)   ? opp.Cross_sell1__c   : '') + '</td></tr>'
            + '<tr><td><b>Sub-Region</b></td><td>'         + (String.isNotBlank(opp.Sub_Region__c)    ? opp.Sub_Region__c    : '') + '</td></tr>'
            + '<tr><td><b>Link</b></td><td><a href="'      + oppUrl + '">' + oppUrl + '</a></td></tr>'
            + '<tr><td><b>Rejected By</b></td><td>'        + (String.isNotBlank(approverName) ? approverName : '') + '</td></tr>'
            + '<tr><td><b>Rejection Date</b></td><td>'     + (rejectionDate != null ? rejectionDate.format() : '') + '</td></tr>'
            + '<tr><td><b>Rejection Comments</b></td><td>' + (String.isNotBlank(comments) ? comments : '') + '</td></tr>'
            + '</table>'
        );
        email.setSaveAsActivity(false);
        dispatchEmail(email);

        // In-app / mobile notification — targets the rejected approval item record
        ApprovalNotificationSender.sendApprovalOutcome(oppId, opp.Name, opp.OwnerId, 'REJECTED');
    }

    // -------------------------------------------------------
    // L1 Approved / Final Approved email

    private static void sendApprovedEmail(Id oppId, Id itemId, Boolean isL1Approved) {
        Opportunity opp = fetchOpp(oppId);
        List<User> owners = [SELECT Email, Name FROM User WHERE Id = :opp.OwnerId LIMIT 1];
        if (owners.isEmpty() || String.isBlank(owners[0].Email)) return;

        String baseUrl  = URL.getOrgDomainUrl().toExternalForm();
        String oppUrl   = baseUrl + '/' + oppId;
        String subject  = isL1Approved
            ? 'OPPORTUNITY L1 APPROVED - ' + opp.Name
            : 'OPPORTUNITY APPROVED - '    + opp.Name;
        String bodyText = isL1Approved
            ? 'Please note the following opportunity has completed <b>Level 1 Approval</b> and has been sent for Level 2 review:'
            : 'Please note the following opportunity has been <b>approved</b> in Salesforce:';

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ owners[0].Email });
        email.setCcAddresses(new List<String>{ ALWAYS_NOTIFY_EMAIL });
        email.setSubject(subject);
        email.setHtmlBody(
            '<p>Hello Team,</p>'
            + '<p>' + bodyText + '</p>'
            + '<table border="1" cellpadding="8" cellspacing="0" style="border-collapse:collapse;font-family:Arial,sans-serif;font-size:14px;">'
            + '<tr><td><b>Opportunity Owner</b></td><td>'  + (opp.Owner   != null ? opp.Owner.Name   : '') + '</td></tr>'
            + '<tr><td><b>Account Name</b></td><td>'       + (opp.Account != null ? opp.Account.Name : '') + '</td></tr>'
            + '<tr><td><b>Opportunity Name</b></td><td>'   + opp.Name + '</td></tr>'
            + '<tr><td><b>Close Date</b></td><td>'         + (opp.CloseDate != null ? String.valueOf(opp.CloseDate) : '') + '</td></tr>'
            + '<tr><td><b>TCV / Amount (USD)</b></td><td>' + (opp.Amount != null ? opp.Amount.format() : '') + '</td></tr>'
            + '<tr><td><b>ACV (USD)</b></td><td></td></tr>'
            + '<tr><td><b>Business Unit</b></td><td>'      + (String.isNotBlank(opp.Business_Unit__c) ? opp.Business_Unit__c : '') + '</td></tr>'
            + '<tr><td><b>Sales Type</b></td><td>'         + (String.isNotBlank(opp.Cross_sell1__c)   ? opp.Cross_sell1__c   : '') + '</td></tr>'
            + '<tr><td><b>Sub-Region</b></td><td>'         + (String.isNotBlank(opp.Sub_Region__c)    ? opp.Sub_Region__c    : '') + '</td></tr>'
            + '<tr><td><b>Link</b></td><td><a href="'      + oppUrl + '">' + oppUrl + '</a></td></tr>'
            + '</table>'
        );
        email.setSaveAsActivity(false);
        dispatchEmail(email);

        // In-app / mobile notification — targets the last approved item record
        ApprovalNotificationSender.sendApprovalOutcome(oppId, opp.Name, opp.OwnerId, isL1Approved ? 'L1_APPROVED' : 'L2_APPROVED');
    }

    // -------------------------------------------------------

    private static Opportunity fetchOpp(Id oppId) {
        return [
            SELECT OwnerId, Owner.Name, Name, StageName, Amount, CloseDate,
                   Account.Name, Business_Unit__c, Cross_sell1__c, Sub_Region__c
            FROM   Opportunity
            WHERE  Id = :oppId
            LIMIT  1
        ];
    }

    private static void dispatchEmail(Messaging.SingleEmailMessage email) {
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(
            new List<Messaging.SingleEmailMessage>{ email }, false
        );
        for (Messaging.SendEmailResult r : results) {
            if (!r.isSuccess()) {
                System.debug('OpportunityApprovalItemHandler: email send FAILED — ' + JSON.serialize(r.getErrors()));
            }
        }
    }
}