package com.svtrucking.logistics.support.audit;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marker annotation for audited actions. Simple runtime-retained annotation used by auditing
 * aspects/filters.
 */
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
public @interface AuditedAction {
  /** Action name, e.g. "driver.create" */
  String value();
}
