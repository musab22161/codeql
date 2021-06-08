/**
 * Provides classes for working with Spring classes and interfaces from
 * `org.springframework.beans`.
 */

import java
import semmle.code.java.dataflow.ExternalFlow

module SpringBeans {
  private class FlowSummaries extends SummaryModelCsv {
    override predicate row(string row) {
      row =
        [
          "org.springframework.beans;PropertyValue;false;PropertyValue;(String,Object);;Argument[0];MapKey of Argument[-1];value",
          "org.springframework.beans;PropertyValue;false;PropertyValue;(String,Object);;Argument[1];MapValue of Argument[-1];value",
          "org.springframework.beans;PropertyValue;false;PropertyValue;(PropertyValue);;Argument[0];Argument[-1];value",
          "org.springframework.beans;PropertyValue;false;PropertyValue;(PropertyValue,Object);;MapKey of Argument[0];MapKey of Argument[-1];value",
          "org.springframework.beans;PropertyValue;false;PropertyValue;(PropertyValue,Object);;Argument[1];MapValue of Argument[-1];value",
          "org.springframework.beans;PropertyValue;false;getName;;;MapKey of Argument[-1];ReturnValue;value",
          "org.springframework.beans;PropertyValue;false;getValue;;;MapValue of Argument[-1];ReturnValue;value",
          "org.springframework.beans;PropertyValues;true;getPropertyValue;;;MapValue of Element of Argument[-1];ReturnValue;value",
          "org.springframework.beans;PropertyValues;true;getPropertyValues;;;Element of Argument[-1];ArrayElement of ReturnValue;value",
          "org.springframework.beans;MutablePropertyValues;true;add;(String,Object);;Argument[0];MapKey of Element of Argument[-1];value",
          "org.springframework.beans;MutablePropertyValues;true;add;(String,Object);;Argument[0];MapKey of Element of ReturnValue;value",
          "org.springframework.beans;MutablePropertyValues;true;add;(String,Object);;Argument[1];MapValue of Element of Argument[-1];value",
          "org.springframework.beans;MutablePropertyValues;true;add;(String,Object);;Argument[1];MapValue of Element of ReturnValue;value",
          "org.springframework.beans;MutablePropertyValues;true;addPropertyValue;(PropertyValue);;Argument[0];Element of Argument[-1];value",
          "org.springframework.beans;MutablePropertyValues;true;addPropertyValue;(PropertyValue);;Argument[0];Element of ReturnValue;value",
          "org.springframework.beans;MutablePropertyValues;true;addPropertyValue;(String,Object);;Argument[0];MapKey of Element of Argument[-1];value",
          "org.springframework.beans;MutablePropertyValues;true;addPropertyValue;(String,Object);;Argument[1];MapValue of Element of Argument[-1];value",
          "org.springframework.beans;MutablePropertyValues;true;addPropertyValues;(Map);;MapKey of Argument[0];MapKey of Element of Argument[-1];value",
          "org.springframework.beans;MutablePropertyValues;true;addPropertyValues;(Map);;MapKey of Argument[0];MapKey of Element of ReturnValue;value",
          "org.springframework.beans;MutablePropertyValues;true;addPropertyValues;(Map);;MapValue of Argument[0];MapValue of Element of Argument[-1];value",
          "org.springframework.beans;MutablePropertyValues;true;addPropertyValues;(Map);;MapValue of Argument[0];MapValue of Element of ReturnValue;value",
          "org.springframework.beans;MutablePropertyValues;true;addPropertyValues;(PropertyValues);;MapKey of Element of Argument[0];MapKey of Element of Argument[-1];value",
          "org.springframework.beans;MutablePropertyValues;true;addPropertyValues;(PropertyValues);;MapKey of Element of Argument[0];MapKey of Element of ReturnValue;value",
          "org.springframework.beans;MutablePropertyValues;true;addPropertyValues;(PropertyValues);;MapValue of Element of Argument[0];MapValue of Element of Argument[-1];value",
          "org.springframework.beans;MutablePropertyValues;true;addPropertyValues;(PropertyValues);;MapValue of Element of Argument[0];MapValue of Element of ReturnValue;value",
          "org.springframework.beans;MutablePropertyValues;true;get;;;MapValue of Element of Argument[-1];ReturnValue;value",
          "org.springframework.beans;MutablePropertyValues;true;getPropertyValue;;;Element of Argument[-1];ReturnValue;value",
          "org.springframework.beans;MutablePropertyValues;true;getPropertyValueList;;;Element of Argument[-1];Element of ReturnValue;value",
          "org.springframework.beans;MutablePropertyValues;true;getPropertyValues;;;Element of Argument[-1];ArrayElement of ReturnValue;value",
          "org.springframework.beans;MutablePropertyValues;true;setPropertyValueAt;;;Argument[0];Element of Argument[-1];value"
        ]
    }
  }
}
