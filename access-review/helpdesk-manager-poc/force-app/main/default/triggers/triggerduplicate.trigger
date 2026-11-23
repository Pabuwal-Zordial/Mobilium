trigger triggerduplicate on Account (before delete) {
    if(trigger.isdelete)
    {
        list<contact> lst = [select id,name, accountid from contact where accountid IN : trigger.oldmap.keyset()];
       
                if(lst!= null)
            {
              for(contact con : lst) 
              {
                  con.accountid = null;
                  //con.contactid = null;
              }
                update lst;
        }
    }
    

}