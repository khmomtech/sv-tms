package com.svtrucking.gateway.web;

import com.svtrucking.gateway.service.ProxyService;
import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ProxyController {

    private final ProxyService proxyService;

    public ProxyController(ProxyService proxyService) {
        this.proxyService = proxyService;
    }

    @RequestMapping("/api/**")
    public ResponseEntity<byte[]> proxyApi(HttpServletRequest request) throws IOException {
        byte[] body = request.getInputStream().readAllBytes();
        return proxyService.forward(request, body);
    }

    @RequestMapping("/uploads/**")
    public ResponseEntity<byte[]> proxyUploads(HttpServletRequest request) throws IOException {
        byte[] body = request.getInputStream().readAllBytes();
        return proxyService.forward(request, body);
    }
}
