public class DeleteBatchClass implements Database.batchable<sobject> {
    
    public database.queryLocator Start(database.batchableContext bc)
    {
        return database.getqueryLocator('select id, rating, SLAExpirationDate__c from account where SLAExpirationDate__c < LAST_N_DAYS:14 ');
        
    }
    public void execute(database.batchableContext bc, list<Account> scope)
    {
        for(account acc : scope)
        {
            acc.rating = 'warm';
        }
        update scope;
    }
    public void finish(database.batchableContext bc)

    {
        
    }

}