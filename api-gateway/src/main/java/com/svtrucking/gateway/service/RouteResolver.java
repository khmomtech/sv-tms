package com.svtrucking.gateway.service;

import com.svtrucking.gateway.config.GatewayRoutesProperties;
import java.net.URI;
import org.springframework.stereotype.Component;

@Component
public class RouteResolver {

    private final GatewayRoutesProperties routes;

    public RouteResolver(GatewayRoutesProperties routes) {
        this.routes = routes;
    }

    public URI resolve(String path) {
        if (path.startsWith("/api/auth/")) {
            return routes.getAuth();
        }
        if (path.startsWith("/api/driver/chat/")) {
            return routes.getCore();
        }
        if (path.startsWith("/api/admin/telematics/")
                || path.startsWith("/api/admin/geofences/")
                || path.startsWith("/api/public/tracking/")) {
            return routes.getTelematics();
        }
        if (path.startsWith("/api/admin/safety-checks/")
                || path.startsWith("/api/public/safety-checks/")) {
            return routes.getSafety();
        }
        if (path.startsWith("/api/driver/")
                || path.startsWith("/api/driver-app/")
                || path.startsWith("/api/notifications/driver/")) {
            return routes.getDriver();
        }
        return routes.getCore();
    }
}
