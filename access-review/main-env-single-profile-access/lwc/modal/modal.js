import { LightningElement, api } from 'lwc';

export default class Modal extends LightningElement {
	@api title;
	showModal = false;
	isLoading = false;

	@api show() {
		this.showModal = true;
	}

	@api hide() {
		this.isLoading = false;
		this.showModal = false;
	}

	@api startLoading() {
		this.isLoading = true; 
	}

	@api stopLoading() {
		this.isLoading = false; 
	}

	@api handleClose() {
		this.stopLoading();
		this.dispatchEvent(new CustomEvent('close'));
		this.hide();
	}
}