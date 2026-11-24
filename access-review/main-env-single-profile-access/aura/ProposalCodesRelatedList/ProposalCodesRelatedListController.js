({
	doInit : function(component, event, helper) {
		var action = component.get("c.getRelatedRecords");

		action.setParams(
			{ recordId : component.get("v.recordId") }
		);

		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				var serverResponse = response.getReturnValue();
				if (serverResponse.isSuccess) {
					component.set("v.listOfProposalCodes", serverResponse.value);
					var customTitle = "Proposal Code (" + serverResponse.value.length + ")";
					component.set("v.cardTitle", customTitle)
				}
			}
		});

		$A.enqueueAction(action);
	}
})