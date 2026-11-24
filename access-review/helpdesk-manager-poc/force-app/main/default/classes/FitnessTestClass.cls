@isTest
public class FitnessTestClass {
    @isTest
    public static void calculateBMITest()
    {
        integer weight = 100;
        double height = 10.00;
       double result = fitness.calculateBMI(weight, height);
        System.assertEquals(1, result, 'Treated count does not match');
            
            }

}