import { LightningElement, api } from 'lwc';

export default class LifecycleHook extends LightningElement {
   

@api message = 'welcome';
constructor() {
    super();
    this.message = this.message + 'life cycle hook';
    console.log('executing constructor');
}

connectedCallback() {
    console.log('executing connected call back');

}
disconnectedCallback(){
    console.log('Executing disconnected connected callback'); 
}
renderedCallback(){
    console.log('Executing rendered call back');
}
/*errorCallback(error,stack){
    console.log('Executing error callback'+error);
}*/




}