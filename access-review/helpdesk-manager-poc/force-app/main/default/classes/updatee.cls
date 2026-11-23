public class updatee {

    public static void main()
    {
        list<account> acc = [select id, name, industry , type , ownership from account where name ='shivam update' ];
        
        if(acc != null)
        {
            for(account acc1 : acc)
          
        acc1.name = ' shi update' ;
            update acc;
        }
        
    }
}