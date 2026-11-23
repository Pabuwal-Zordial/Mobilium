public with sharing class PPOValidationService {
    public class FlowInput {
        @InvocableVariable(required=true)
        public Id recordId;
    }

    public class FlowOutput {
        @InvocableVariable
        public String errorMessage;
    }

    @InvocableMethod(label='Validate PPO Input' description='Validates PPO fields before submission')
    public static List<FlowOutput> validatePPOInput(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();

        for (FlowInput input : inputs) {
            FlowOutput output = new FlowOutput();
            Opportunity opp = [SELECT Id, StageName, Delivery_Involved__c, Customer_Services_Involved__c, Managed_Services_Involved__c, Business_Type__c, Cross_sell1__c, Business_Unit__c, Opportunity_Approval_Status__c, Second_Approval_Status__c
                               FROM Opportunity
                               WHERE Id = :input.recordId
                               LIMIT 1];

            String validationMessage = cls_PPOApprovalHandler.validateRelatedOpp(opp);
            if (validationMessage != null) {
                output.errorMessage = validationMessage;
            }

            outputs.add(output);
        }

        return outputs;
    }
}