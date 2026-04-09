package com.svtrucking.logistics.model;

import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
@Deprecated
@jakarta.persistence.Entity
public class OrderAddress extends CustomerAddress {
    // Deprecated compatibility subclass. Use `CustomerAddress` instead.
}
