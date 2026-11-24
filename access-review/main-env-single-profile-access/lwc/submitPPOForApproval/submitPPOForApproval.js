import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import submitApproval from "@salesforce/apex/cls_PPOApprovalHandler.initiateApproval";
import { NavigationMixin } from "lightning/navigation";

export default class PpoApprovalRequest extends NavigationMixin(LightningElement) {
    @api recordId;
    isSubmitting = false;

    @api invoke() {
        if (this.isSubmitting) return;

        this.isSubmitting = true;
        submitApproval({ ppoId: this.recordId })
            .then((result) => this.handleApprovalResponse(result))
            .catch((error) => {
                console.error("Error submitting approval:", error);
                this.showErrorToast(this.parseError(error));
            })
            .finally(() => {
                this.isSubmitting = false;
            });
    }

    /**
     * Handle the approval response
     * @param {String} state - Response from Apex method
     */
    handleApprovalResponse(state) {
        if (state === "Success") {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "PPO Details",
                    message: "Submitted for Approval",
                    variant: "success"
                })
            );

            // Close the action screen and refresh
            this.closeAndRefresh();
        } else if (state && state.indexOf("Warning") !== -1) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "PPO Approval Warning",
                    message: state.replace("Warning: ", ""),
                    variant: "warning",
                    mode: "sticky" // Keep the toast until user dismisses it
                })
            );

            // Close the action screen and refresh
            this.closeAndRefresh();
        } else {
            // Show error as toast instead of displaying in component
            this.showErrorToast(state);
        }
    }

    /**
     * Show error toast message
     * @param {String} errorMessage - Error message to display
     */
    showErrorToast(errorMessage) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: "PPO Approval Error",
                message: errorMessage,
                variant: "error",
                mode: "sticky"
            })
        );

        // Close the action screen
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /**
     * Close action screen and refresh view
     */
    closeAndRefresh() {
        this.dispatchEvent(new CloseActionScreenEvent());

        this.refreshPage();
    }

    refreshPage() {
        // Reloads the current page by navigating to it again
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.recordId, // Record ID of the current page
                objectApiName: "PPO_Sales_Governance__c", // Object name of the current record
                actionName: "view" // Action to perform (view)
            }
        });
    }

    /**
     * Parse error messages from Apex exceptions
     * @param {Object} error - The error object from Apex
     * @returns {String} - Formatted error message
     */
    parseError(error) {
        if (error?.body) {
            // Handle different error formats
            if (Array.isArray(error.body)) {
                return error.body.map((e) => e.message).join(", ");
            }

            if (error.body.pageErrors && Array.isArray(error.body.pageErrors)) {
                return error.body.pageErrors.map((e) => e.message).join(", ");
            }

            if (error.body.fieldErrors) {
                const fieldErrorMessages = [];
                Object.values(error.body.fieldErrors).forEach((fieldErrors) => {
                    fieldErrors.forEach((fieldError) => {
                        fieldErrorMessages.push(fieldError.message);
                    });
                });
                if (fieldErrorMessages.length > 0) {
                    return fieldErrorMessages.join(", ");
                }
            }

            if (typeof error.body.message === "string") {
                return error.body.message;
            }
        }

        if (typeof error.message === "string") {
            return error.message;
        }

        return "An unexpected error occurred while submitting the approval request.";
    }
}