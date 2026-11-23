public class oddeven {

    public static void main()
    {
       // integer temp = 0;
     
     for(integer i = 0; i<=6;i++)
      {
          if(i==0)
          {
              system.debug(i);
          }
          if(math.mod(i,3)!=0)
              system.debug(i);
      }
    }
}