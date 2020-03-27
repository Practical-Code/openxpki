import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action, computed, set } from "@ember/object";
import { next } from '@ember/runloop'
import { debug } from '@ember/debug';
import $ from "jquery";

export default class OxifieldSelectComponent extends Component {
    @tracked customMode = false;

    @computed("args.content.{options,prompt,is_optional}")
    get options() {
        debug("oxifield-select (" + this.args.content.name + "): options");
        var options, prompt, ref;
        prompt = this.args.content.prompt;
        if (!prompt && this.args.content.is_optional) {
            prompt = "";
        }
        options = (this.args.content.options || []);
        if (typeof prompt === "string" && prompt !== ((ref = options[0]) != null ? ref.label : void 0)) {
            return [ { label: prompt, value: "" } ].concat(options);
        } else {
            return options;
        }
    }

    @computed("args.content.{options,editable,is_optional}")
    get isStatic() {
        let options = this.args.content.options;
        let isEditable = this.args.content.editable;
        let isOptional = this.args.content.is_optional;
        if (options.length === 1 && !isEditable && !isOptional) {
            // FIXME side effect of setting value - move somewhere else
            set(this.args.content, "value", this.options[0].value);
            return true;
        } else {
            return false;
        }
    }

    @computed("options", "args.content.value")
    get isCustomValue() {
        let values = this.options.map(o => o.value);
        let isCustom = values.indexOf[this.args.content.value] < 0;
        this.customMode = isCustom;
        return isCustom;
    }

    // no computed value - no need to refresh later on
    // (and making it computed causes strange side effects when optionSelected() is triggered)
    get sanitizedValue() {
        debug("oxifield-select (" + this.args.content.name + "): sanitizedValue(" + this.args.content.value + ")");
        var value = this.args.content.value;
        if (typeof value === "string") return value;

        var options = this.options;
        var ref;
        return ((ref = options[0]) != null ? ref.value : void 0) || "";
    }

    @action
    toggleCustomMode() {
        this.toggleProperty("customMode");
        if (!this.customMode) {
            if (this.isCustomValue) {
                set(this.args.content, "value", this.options[0].value);
            }
        }
        next(this, () => {
            $("input,select")[0].focus();
        });
    }

    @action
    optionSelected(value, label) {
        debug("oxifield-select (" + this.args.content.name + "): optionSelected(" + value + ")");
        set(this.args.content, "value", value);
        this.args.onChange();
    }
}
