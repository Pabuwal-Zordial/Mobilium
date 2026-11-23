@IsTest
private class PPOFileUploadValidationTest {
    // Helper to create a file linked to a record
    private static void createFileLinkedTo(Id parentId) {
        ContentVersion cv = new ContentVersion(Title = 'PPO_Test_File', PathOnClient = 'PPO_Test_File.pdf', VersionData = Blob.valueOf('dummy file body'), FirstPublishLocationId = parentId);
        insert cv;

        // (Optional) sanity check that the link exists
        Id contentDocId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ]
        .ContentDocumentId;

        System.assertNotEquals(null, [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :parentId AND ContentDocumentId = :contentDocId LIMIT 1].Id);
    }

    @IsTest
    static void validate_noFile_returnsError() {
        Account a = new Account(Name = 'No File');
        insert a;

        PPOFileUploadValidation.FlowInput inp = new PPOFileUploadValidation.FlowInput();
        inp.recordId = a.Id;

        Test.startTest();
        List<PPOFileUploadValidation.FlowOutput> outs = PPOFileUploadValidation.validate(new List<PPOFileUploadValidation.FlowInput>{ inp });
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals('A file upload is required before submitting the PPO.', outs[0].errorMessage);
    }

    @IsTest
    static void validate_withFile_returnsNoError() {
        Account a = new Account(Name = 'With File');
        insert a;

        createFileLinkedTo(a.Id);

        PPOFileUploadValidation.FlowInput inp = new PPOFileUploadValidation.FlowInput();
        inp.recordId = a.Id;

        Test.startTest();
        List<PPOFileUploadValidation.FlowOutput> outs = PPOFileUploadValidation.validate(new List<PPOFileUploadValidation.FlowInput>{ inp });
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals(null, outs[0].errorMessage);
    }

    @IsTest
    static void validate_bulk_mixedInputs() {
        Account a1 = new Account(Name = 'Bulk No File');
        Account a2 = new Account(Name = 'Bulk With File');
        insert new List<Account>{ a1, a2 };

        createFileLinkedTo(a2.Id);

        PPOFileUploadValidation.FlowInput i1 = new PPOFileUploadValidation.FlowInput();
        i1.recordId = a1.Id;

        PPOFileUploadValidation.FlowInput i2 = new PPOFileUploadValidation.FlowInput();
        i2.recordId = a2.Id;

        Test.startTest();
        List<PPOFileUploadValidation.FlowOutput> outs = PPOFileUploadValidation.validate(new List<PPOFileUploadValidation.FlowInput>{ i1, i2 });
        Test.stopTest();

        System.assertEquals(2, outs.size());

        System.assertEquals('A file upload is required before submitting the PPO.', outs[0].errorMessage);
        System.assertEquals(null, outs[1].errorMessage);
    }
}