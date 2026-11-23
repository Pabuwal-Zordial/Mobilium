public class soql {
    public static void main()
    {
        aggregateresult[] agg = [select industry , sum(annualrevenue) ar from account group by industry];
        system.debug(agg.size());
        if( agg != null)
        {
            for(aggregateresult agg1 : agg )
            system.debug('industry is ' + agg1.get('industry') + ' record count is ' + agg1.get('ar') );
        }
    }

}