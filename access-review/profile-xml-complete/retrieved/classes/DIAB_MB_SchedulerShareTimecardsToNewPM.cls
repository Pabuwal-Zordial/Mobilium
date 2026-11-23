global class DIAB_MB_SchedulerShareTimecardsToNewPM implements Schedulable {

    global void execute(SchedulableContext sc) {
        // Execute the batch job with a scope size of 200
        Database.executeBatch(new DIAB_MB_BatchShareTimecardsToNewPM(), 200);
    }

    // Method to schedule this batch daily at 12 PM
    public static void scheduleDailyAtNoon() {
        // Cron expression: '0 0 12 * * ?' => At 12:00 PM every day
        System.schedule(
            'DIAB_MB_ShareTimecards_Daily_12PM', 
            '0 0 12 * * ?', 
            new DIAB_MB_SchedulerShareTimecardsToNewPM()
        );
    }
}