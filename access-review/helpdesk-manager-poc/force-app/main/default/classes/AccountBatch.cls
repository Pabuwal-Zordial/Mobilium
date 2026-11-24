Global class AccountBatch implements Database.Batchable<SObject>, Database.Stateful {

    Global Decimal totalLeadsRevenue= 0.00;

    Global Database.QueryLocator start(Database.BatchableContext bContext)
    {
       string query = 'select id , AnnualRevenue, name from Account where AnnualRevenue != null';
        return database.getqueryLocator(query);
    }
global void Execute(Database.BatchableContext bContext, List<sobject> query )
{
    if(query != null)
    {
        for(sobject sobj : query)
        {
            account acc = (account)sobj;
            totalLeadsRevenue += acc.AnnualRevenue;
        
        }
    }
}
global void Finish(database.BatchableContext bContext)
{
    AsyncApexJob jobidDetails = [select id from AsyncApexJob where id =: bcontext.getjobID()];

    MessageUtilityClass.sendMail(jobidDetails,totalLeadsRevenue);

}
    
}