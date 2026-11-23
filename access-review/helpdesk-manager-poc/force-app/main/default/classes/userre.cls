public class userre {
    public static void main(string namee)
    {
        if(namee != null && namee!= '')
        {
           namee += '%';
        string use = 'select name, isactive from user where name like : namee';
            
           
            system.debug(use);
            
        
         list<user> lis  = database.query(use);
            system.debug(lis);
            for(user lis1 : lis)
            {
                lis1.isactive  = false;
                update lis;
            }
            system.debug(lis);
       
    }
       

}
}