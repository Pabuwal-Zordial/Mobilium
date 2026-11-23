public class UpdateOppsPendingApprovalsBatch implements Database.Batchable<sObject>, Database.Stateful {

    // The four processes DynamicApprovalEngine actually submits to today. Reassignment on any
    // of them is routed to DynamicApprovalEngine.handleReassigned so Pending_Approvers__c is
    // recomputed the same way the engine already computes it (live ProcessInstanceWorkitem
    // actors). Non_Standard_Approval keeps its original (legacy) touch-update behavior.
    private static final Set<String> DYNAMIC_APPROVAL_PROCESS_DEVELOPER_NAMES = new Set<String>{
        'Opportunity_Dynamic_Approvals_L1',
        'Opportunity_Dynamic_Approvals_L2',
        'Opportunity_Dynamic_Approvals_SA_L1',
        'Opportunity_Dynamic_Approvals_SA_L2'
    };

    // Populated once in start() and reused across execute() chunks.
    private Set<Id> dynamicApprovalProcessDefIds = new Set<Id>();

    public Database.QueryLocator start(Database.BatchableContext BC)
    {
      // Non_Standard_Approval is not part of the approval processes currently in use
      // (only the four Opportunity_Dynamic_Approvals_* processes above are active) —
      // kept here only for its legacy touch-update behavior below, in case any old
      // pending instances still exist under it.
      Set<String> relevantDeveloperNames = new Set<String>(DYNAMIC_APPROVAL_PROCESS_DEVELOPER_NAMES);
      relevantDeveloperNames.add('Non_Standard_Approval');

      Set<Id> processDefIds = new Set<Id>();
      for (ProcessDefinition pd : [SELECT Id, DeveloperName FROM ProcessDefinition WHERE DeveloperName IN :relevantDeveloperNames]) {
          processDefIds.add(pd.Id);
          if (DYNAMIC_APPROVAL_PROCESS_DEVELOPER_NAMES.contains(pd.DeveloperName)) {
              dynamicApprovalProcessDefIds.add(pd.Id);
          }
      }

      // Filters on ProcessInstance.ProcessDefinitionId (a direct, indexed Id lookup) instead of
      // traversing ProcessInstance.ProcessDefinition.Name/DeveloperName — see
      // DynamicApprovalEngine.getProcessDefinitionId for why that two-hop text traversal is
      // rejected as a non-selective filter against this org's real data volume.
      return Database.getQueryLocator([
          SELECT ProcessInstance.TargetObject.Id, ProcessInstance.ProcessDefinitionId
          FROM   ProcessInstanceStep
          WHERE  StepStatus = 'Reassigned'
          AND    ProcessInstance.Status = 'Pending'
          AND    ProcessInstance.ProcessDefinitionId IN :processDefIds
      ]);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope)
    {
          List<ProcessInstanceStep> processInstanceSteps = (List<ProcessInstanceStep>)scope;
          Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
          Set<Id> dynamicApprovalOppIds = new Set<Id>();

          for (ProcessInstanceStep step : processInstanceSteps)
          {
            Id targetId = step.ProcessInstance.TargetObject.Id;
            if (targetId == null || targetId.getsObjectType() != Opportunity.sObjectType) continue;

            if (dynamicApprovalProcessDefIds.contains(step.ProcessInstance.ProcessDefinitionId)) {
                dynamicApprovalOppIds.add(targetId);
            } else if (!oppsToUpdate.containsKey(targetId)) {
                oppsToUpdate.put(targetId, new Opportunity(Id = targetId));
            }
          }

          if (!dynamicApprovalOppIds.isEmpty()) {
              DynamicApprovalEngine.handleReassigned(dynamicApprovalOppIds);
          }

          if (!oppsToUpdate.isEmpty()) {
              List<Database.SaveResult> srList = Database.update(oppsToUpdate.values(), false);

              for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully updated opportunity. Opportunity ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Opportunity fields that affected this error: ' + err.getFields());
                    }
                }
            }
          }
    }

    public void finish(Database.BatchableContext BC)
    {

    }

  }