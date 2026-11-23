trigger checka on Contact (before insert, before update)
{
     if(trigger.isinsert && (trigger.isbefore || trigger.isupdate))
       {
           for(contact con : trigger.new)
           {
               if(con.accountid == null)
               {
                   con.adderror('must have an account');
               }
           }
       }

}