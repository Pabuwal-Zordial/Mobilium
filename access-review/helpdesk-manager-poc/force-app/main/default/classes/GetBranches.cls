public class GetBranches {
    @AuraEnabled(cacheable=true)
    public static list<Branch__c> GetBranch(string bankId) {
        list<Branch__c> bran = [SELECT Id, Name, Bank__r.Name from Branch__c where Bank__c != null and Bank__c =: bankId
          ];
        return bran;
    }
    @AuraEnabled(cacheable=true)
    public static list<Bank__c> GetBank() {
        list<Bank__c> GetBank = [SELECT Id, Name from Bank__c ];
        return GetBank;
    }


}