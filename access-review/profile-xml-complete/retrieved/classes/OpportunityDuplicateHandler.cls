public class OpportunityDuplicateHandler {

    public static void checkDuplicates(List<Opportunity> newOpps) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : newOpps) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }

        Map<Id, List<Opportunity>> existingOppsByAccount = new Map<Id, List<Opportunity>>();
        for (Opportunity opp : [
            SELECT Id, Name, AccountId,Account.name,Account.Sub_Region__c,Business_Unit__c
            FROM Opportunity
            WHERE AccountId IN :accountIds and Converted_from_Lead__c=true
        ]) {
            if (!existingOppsByAccount.containsKey(opp.AccountId)) {
                existingOppsByAccount.put(opp.AccountId, new List<Opportunity>());
            }
            existingOppsByAccount.get(opp.AccountId).add(opp);
        }

        for (Opportunity newOpp : newOpps) {
            List<Opportunity> existingOpps = existingOppsByAccount.get(newOpp.AccountId);
            if (existingOpps == null) continue;

            Set<String> newBU = new Set<String>();
            if (newOpp.Business_Unit__c != null)
                newBU.addAll(newOpp.Business_Unit__c.split(';'));

            for (Opportunity oldOpp : existingOpps) {
                if (newOpp.Id == oldOpp.Id) continue; // skip same record

                Set<String> oldBU = new Set<String>();
                if (oldOpp.Business_Unit__c != null)
                    oldBU.addAll(oldOpp.Business_Unit__c.split(';'));

                oldBU.retainAll(newBU); // check for overlap
                if (!oldBU.isEmpty()) {
                    sendDuplicateEmail(newOpp, oldOpp, oldBU);
                }
            }
        }
    }

    public static void sendDuplicateEmail(Opportunity newOpp, Opportunity existingOpp, Set<String> overlappingBU) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { 'sunita.char@mobileum.com','salesdev@mobileum.com' }); // set your email
        mail.setSubject('Duplicate Opportunity Detected');
        mail.setPlainTextBody(
            'Duplicate Opportunity Found!\n\n' +
            'New Opportunity: ' + newOpp.Name + '\n' +
            'Existing Opportunity: ' + existingOpp.Name + '\n' +
            'Overlapping Business Units: ' + String.join(new List<String>(overlappingBU), ', ') + '\n' +
            'Account Name: ' + existingOpp.Account.Name + '\n' +
            'Account ID: ' + newOpp.AccountId+ '\n' +
            'Sub-Region : '+ existingOpp.Account.Sub_Region__c
        );
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}