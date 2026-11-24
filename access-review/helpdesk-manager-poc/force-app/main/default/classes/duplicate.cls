public class duplicate {
    public static void main()
    {
        list<string> lst = new list<string>{'shivam','pabu','pabuwal','pabu'};
            set<string> set1 = new set<string>();
        set1.addAll(lst);
        system.debug('list is ' + lst + 'set is ' + set1);
    } 

}