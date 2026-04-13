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
        if (path.startsWith("/api/driver/dispatches/")
                || path.equals("/api/driver/dispatches")
                || path.startsWith("/api/driver/banners/")
                || path.startsWith("/api/driver/home-layout/")
                || path.equals("/api/driver/me/profile")
                || path.equals("/api/driver/current-assignment")
                || path.matches("^/api/driver/\\d+/current-assignment$")
                || path.equals("/api/driver/me/vehicle")
                || path.equals("/api/driver/my-vehicle")) {
            return routes.getCore();
        }
        if (path.startsWith("/api/driver-app/incidents")) {
            return routes.getCore();
        }
        if (path.equals("/api/driver-app/bootstrap")) {
            return routes.getCore();
        }
        if (path.startsWith("/api/driver/chat/")) {
            return routes.getCore();
        }
        if (path.startsWith("/api/driver/tracking/session/")
                || path.startsWith("/api/driver/device/")
                || path.startsWith("/api/driver/location/")
                || path.startsWith("/api/driver/presence/")
                || path.equals("/api/driver/update-device-token")) {
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
        if (path.startsWith("/api/public/app-version/")
                || path.equals("/api/public/app-version")) {
            return routes.getDriver();
        }
        if (path.startsWith("/api/notifications/driver/")) {
            return routes.getCore();
        }
        if (path.startsWith("/api/driver/")
                || path.startsWith("/api/driver-app/")) {
            return routes.getDriver();
        }
        return routes.getCore();
    }
}
