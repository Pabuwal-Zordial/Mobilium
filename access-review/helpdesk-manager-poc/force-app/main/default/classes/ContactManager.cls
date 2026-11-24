public with sharing class ContactManager {
    
    @AuraEnabled(cacheable=true)
    public static list<Contact> fetchAllContacts(string accId) {
        List<Contact> conList = [select id,Name,Email,Account.Name from Contact where  Account.name != null and AccountId = : accId];
        return conList;
    }

    @AuraEnabled(cacheable=true)
    public static list<Account> fetchAccount() {
        List<Account> accList = [select id , Name from Account order by name asc];
        return accList;
    }
}