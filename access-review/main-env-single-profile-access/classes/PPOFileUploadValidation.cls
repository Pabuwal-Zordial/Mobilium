public with sharing class PPOFileUploadValidation {
    public class FlowInput {
        @InvocableVariable(required=true)
        public Id recordId;
    }

    public class FlowOutput {
        @InvocableVariable
        public String errorMessage;
    }

    @InvocableMethod(label='Validate PPO File Upload' description='Checks if a file is attached to the PPO')
    public static List<FlowOutput> validate(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();

        for (FlowInput input : inputs) {
            FlowOutput output = new FlowOutput();

            List<ContentDocumentLink> files = [
                SELECT Id
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :input.recordId
                LIMIT 1
            ];

            if (files.isEmpty()) {
                output.errorMessage = 'A file upload is required before submitting the PPO.';
            }

            outputs.add(output);
        }

        return outputs;
    }
}