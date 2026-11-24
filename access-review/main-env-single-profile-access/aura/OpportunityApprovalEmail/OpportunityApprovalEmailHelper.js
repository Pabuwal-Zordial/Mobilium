({
    sendApprovalEmail: function (component) {
        component.set('v.isLoading', true);

        var action = component.get('c.sendApprovalEmail');
        action.setParams({ opportunityId: component.get('v.recordId') });

        action.setCallback(this, function (response) {
            component.set('v.isLoading', false);

            var state  = response.getState();
            var result = response.getReturnValue();

            if (state === 'SUCCESS') {
                var prefix  = result ? result.split(':')[0] : 'ERROR';
                var message = result ? result.substring(result.indexOf(':') + 1) : 'An unexpected error occurred.';

                var toastType, toastTitle, toastMode;

                if (prefix === 'SUCCESS') {
                    toastType  = 'success';
                    toastTitle = 'Email Sent';
                    toastMode  = 'dismissible';
                } else if (prefix === 'VALIDATION_ERROR') {
                    toastType  = 'warning';
                    toastTitle = 'Validation Failed';
                    toastMode  = 'sticky';
                } else if (prefix === 'CONFIG_ERROR') {
                    toastType  = 'error';
                    toastTitle = 'Configuration Error';
                    toastMode  = 'sticky';
                } else if (prefix === 'EMAIL_ERROR') {
                    toastType  = 'error';
                    toastTitle = 'Email Send Failed';
                    toastMode  = 'sticky';
                } else {
                    toastType  = 'error';
                    toastTitle = 'Error';
                    toastMode  = 'sticky';
                }

                this.showToastAndClose(toastTitle, message, toastType, toastMode);

            } else {
                var errors = response.getError();
                var errMsg = (errors && errors[0] && errors[0].message)
                    ? errors[0].message
                    : 'An unexpected server error occurred.';
                this.showToastAndClose('Error', errMsg, 'error', 'sticky');
            }
        });

        $A.enqueueAction(action);
    },

    showToastAndClose: function (title, message, type, mode) {
        var toast = $A.get('e.force:showToast');
        toast.setParams({ title: title, message: message, type: type, mode: mode });
        $A.get('e.force:closeQuickAction').fire();
        toast.fire();
        $A.get('e.force:refreshView').fire();
    }
})