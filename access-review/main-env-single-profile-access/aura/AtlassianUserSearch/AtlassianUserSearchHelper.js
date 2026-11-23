({
	serverSearch : function(component, searchTermInput) {
		var action = component.get('c.searchUsers');

		action.setParams({ searchTerm: searchTermInput });
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var results = response.getReturnValue()
				if (results.length > 0) {
					component.set('v.data', results);
				}
				else {
					this.showToast('info', 'No results found.', 'Info', 'dismissible');
				}
				component.set("v.processing", false);
			}
			else {
				component.set("v.processing", false);
				this.showToast('error', response.getError()[0].message, 'Error', 'dismissible');
			}
		});

		$A.enqueueAction(action);
	},
	showToast : function(type, message, title, mode) {
		var toastEvent = $A.get('e.force:showToast');
		toastEvent.setParams({
			type : type,
			message : message,
			title : title,
			mode : mode
		});
		toastEvent.fire();
	},
})