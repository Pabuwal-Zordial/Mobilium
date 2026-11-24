({
	doInit: function (component) {
		var action = component.get('c.initiateApproval')
		action.setParams({
			oppId: component.get('v.recordId')
		})
		action.setCallback(this, function (response) {
			var state = response.getReturnValue()
			var resultsToast
			if (state === 'Success') {
				resultsToast = $A.get('e.force:showToast')
				resultsToast.setParams({
					title: 'Opportunity',
					message: 'Submitted for Approval'
				})

				// Update the UI: close panel, show toast, refresh account page
				$A.get('e.force:closeQuickAction').fire()
				resultsToast.fire()

				// Reload the view
				$A.get('e.force:refreshView').fire()
			} else if (state && state.indexOf('Warning') !== -1) {
				resultsToast = $A.get('e.force:showToast')
				resultsToast.setParams({
					title: 'Delivery | MS | CS involved',
					message: state.replace('Warning: ', ''),
					type: 'warning',
					mode: 'sticky' // Keep the toast until the user dismisses it
				})

				// Update the UI: close panel, show toast, refresh account page
				$A.get('e.force:closeQuickAction').fire()
				resultsToast.fire()

				// Reload the view
				$A.get('e.force:refreshView').fire()
			} else {
				component.set('v.recordError', state)
			}
		})
		$A.enqueueAction(action)
	}
})