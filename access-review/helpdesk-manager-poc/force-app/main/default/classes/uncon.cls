public class uncon {
    public static void main()
    {
      //  if(account12 != null && account12 != '')
        {
          //  account acc = [select id, name from account where name =: account12 limit 1];
            list<contact> con  = [select id,name,accountid from contact where accountid = '0012w00000Et4dkAAB'];
            system.debug(con.size());
            for( contact con1 : con)
            {
                system.debug(con1);
                con1.accountid = '';
                insert con;
                system.debug(con);
            }
        }
    }
    
       

}