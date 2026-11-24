import { LightningElement, track } from 'lwc';
export default class MyFirstComp extends LightningElement {
@track dynamicGreet = 'World';

greetingChangeHandler(event)
{
    this.dynamicGreet = event.target.value;
}
}