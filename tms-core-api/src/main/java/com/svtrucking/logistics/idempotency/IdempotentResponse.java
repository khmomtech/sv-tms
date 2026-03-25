package com.svtrucking.logistics.idempotency;

import java.io.Serializable;

/**
 * Serializable wrapper for a cached HTTP response body and status code.
 * Stored in Redis for idempotency replay.
 */
public class IdempotentResponse implements Serializable {

    private static final long serialVersionUID = 1L;

    private int status;
    private String body;
    private String contentType;

    public IdempotentResponse() {
    }

    public IdempotentResponse(int status, String body, String contentType) {
        this.status = status;
        this.body = body;
        this.contentType = contentType;
    }

    public int getStatus() {
        return status;
    }

    public void setStatus(int status) {
        this.status = status;
    }

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }
}
