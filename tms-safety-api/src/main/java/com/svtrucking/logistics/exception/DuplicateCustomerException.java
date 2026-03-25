package com.svtrucking.logistics.exception;

/**
 * Exception thrown when attempting to create or update a customer
 * with data that duplicates an existing customer.
 */
public class DuplicateCustomerException extends RuntimeException {
    
    public DuplicateCustomerException(String message) {
        super(message);
    }
    
    public DuplicateCustomerException(String field, String value) {
        super(String.format("Customer with %s '%s' already exists", field, value));
    }
}
