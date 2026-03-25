package com.svtrucking.gateway.config;

import java.net.URI;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "gateway.routes")
public class GatewayRoutesProperties {

    private URI auth = URI.create("http://localhost:8083");
    private URI core = URI.create("http://localhost:8080");
    private URI driver = URI.create("http://localhost:8084");
    private URI telematics = URI.create("http://localhost:8082");
    private URI safety = URI.create("http://localhost:8087");

    public URI getAuth() {
        return auth;
    }

    public void setAuth(URI auth) {
        this.auth = auth;
    }

    public URI getCore() {
        return core;
    }

    public void setCore(URI core) {
        this.core = core;
    }

    public URI getDriver() {
        return driver;
    }

    public void setDriver(URI driver) {
        this.driver = driver;
    }

    public URI getTelematics() {
        return telematics;
    }

    public void setTelematics(URI telematics) {
        this.telematics = telematics;
    }

    public URI getSafety() {
        return safety;
    }

    public void setSafety(URI safety) {
        this.safety = safety;
    }
}
