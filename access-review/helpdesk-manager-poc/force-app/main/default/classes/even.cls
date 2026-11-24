public class even {
    public static void main()
    {
        list<integer> lst = new list<integer>{0,1,2,3,4,5,6,7,8,9};
            integer i;
        integer even=0;
            integer odd=0;
                integer zero =0;
        {
        for(i=0;i<lst.size();i++)
            if(math.mod(lst[i], 2) == 0)
            even++;
            else if(math.mod(lst[i],2) != 0)
             odd++;
        /*else (lst[i] = 0)
        {
            zero++;
        }*/
        }
        
        
          system.debug('even no are '+ even);
        system.debug('odd no are '+ odd);
        system.debug('zero no are '+ zero);
       // list<integer> lst1 = new list<integer>();
       //     lst1.addAll(lst);
        //    system.debug(lst1.size());
            
    }

}