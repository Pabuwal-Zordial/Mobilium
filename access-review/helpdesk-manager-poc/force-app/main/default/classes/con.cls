public class con {
    public static void main()
    {
      //  string[] namelist = new string[list{'banking' , 'finance' , 'healthcare'};
            
            
           string con = 'select id,firstname, lastname, Account.Name, account.rating, account.owner.lastname from contact where accountid != null';
        list<contact> lstcon = database.query(con);
        system.debug(lstcon.size());
                                
       // system.debug(latcon.size());
                                 
        if(! lstcon.isempty())
            {
                for(contact con1 : lstcon)
                {
                    system.debug(con1.AccountId);
                system.debug('contact name is ' + con1.lastname);
               // system.debug('email' + con1.email);
                system.debug('account name ' + con1.account.name);
                  system.debug('owner last name ' + con1.account.owner.lastname);
                    
                //system.debug('accoutn name is ' + con.account.name);
             //  system.debug('name' + con1.phone);
            }
            }
       // system.debug(con.id);
            
        }
    }