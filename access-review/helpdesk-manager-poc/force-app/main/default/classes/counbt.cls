public class counbt {
    public static void main()
    {
        list<integer> lst = new list<integer>{1,2,3,4,5,6,7,8,9};
            integer i;
        integer count=0;
       integer odd=0;
        
        {
        for(i=0;i<lst.size();i++)
            if(math.mod(lst[i], 3) == 0 )
            
            system.debug(lst[i]);
            
            else
             odd++;
        }
        
      
        
        
          system.debug('count no are '+ count);
        system.debug('odd no are '+ odd);
     //   system.debug('zero no are '+ zero);
       // list<integer> lst1 = new list<integer>();
       //     lst1.addAll(lst);
        //    system.debug(lst1.size());
            
    }
    }