global class contactstoupdate implements Database.Batchable<sObject>
{
   global database.QueryLocator Start(database.BatchableContext bContext)
   {
       string contactstoquery = 'Select id,name, AssistantPhone , mobilephone from contact';
      return database.getQueryLocator(contactstoquery);
   }
    Global Void Execute(database.batchablecontext bcontext, list<Sobject> Recordstoprocess)
    {
        list<contact> contactstoupdate = new list<contact>() ;
      if(!recordstoprocess.isEmpty())   
{
for ( sobject contactrecord : Recordstoprocess) 
{
    contact con = (contact) contactrecord;
  con.AssistantPhone = '123';
con.MobilePhone = '12345';
    con.Title =  'manager';
  //  con.OtherAddress = 'H-74, banipark';
    contactstoupdate.add(con);
}
if(!contactstoupdate.isEmpty())
{
    update contactstoupdate;
}
}
    }
Global void finish(database.Batchablecontext bcontext)
{
    system.debug('batch jobid... : ' + bcontext.getJobId());
AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bcontext.getJobId()];
}
    
}