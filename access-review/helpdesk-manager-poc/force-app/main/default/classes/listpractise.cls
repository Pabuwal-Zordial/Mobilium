public class listpractise {
public static void main()
    {
    list<integer> lst = new list<integer>{149,1,3,248,2,8,70,5};
        map<integer,string> maplist = new map<integer,string>();
        maplist.put(1,'shivam');
        system.debug(maplist.containskey(3));
        system.debug(maplist.size());
        system.debug(lst);
    integer i;
      for(i =0;i<lst.size();i++)
    {
      integer j;
       for(j=i+1;j<lst.size();j++)
       {
              if(lst[i] <= lst[j])
                  break;
       }
        if(j==lst.size())
            system.debug(lst[i]);
       }
       
    }
   

}