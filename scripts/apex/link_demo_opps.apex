Account reliance = [SELECT Id FROM Account WHERE Name = 'Reliance Communications' LIMIT 1];
Account airtel = [SELECT Id FROM Account WHERE Name = 'Airtel Group' LIMIT 1];
Account vodafone = [SELECT Id FROM Account WHERE Name = 'Vodafone Group' LIMIT 1];

Account_Plan__c planReliance = [SELECT Id FROM Account_Plan__c WHERE Account__c = :reliance.Id AND Fiscal_Year__c = 'FY2027' LIMIT 1];
Account_Plan__c planAirtel = [SELECT Id FROM Account_Plan__c WHERE Account__c = :airtel.Id AND Fiscal_Year__c = 'FY2027' LIMIT 1];
Account_Plan__c planVodafone = [SELECT Id FROM Account_Plan__c WHERE Account__c = :vodafone.Id AND Fiscal_Year__c = 'FY2027' LIMIT 1];

List<Opportunity> opps = [SELECT Id, Name, AccountId, Account_Plan__c FROM Opportunity WHERE Name LIKE 'Demo%'];
for (Opportunity o : opps) {
    if (o.Name.contains('Reliance')) {
        o.AccountId = reliance.Id;
        o.Account_Plan__c = planReliance.Id;
    } else if (o.Name.contains('Airtel')) {
        o.AccountId = airtel.Id;
        o.Account_Plan__c = planAirtel.Id;
    } else if (o.Name.contains('Vodafone')) {
        o.AccountId = vodafone.Id;
        o.Account_Plan__c = planVodafone.Id;
    }
}
update opps;
System.debug('Re-parented and linked demo opportunities: ' + opps.size());
