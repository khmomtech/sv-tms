package com.svtrucking.telematics.controller.internal;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Simple HTML dashboard for internal telemetry stream status.
 * <p>
 * This page is intended for internal debugging and is protected by the same internal API key filter.
 */
@RestController
@RequestMapping("/api/internal/telemetry")
public class TelemetryDashboardController {

    @GetMapping(value = "/dashboard", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> dashboard() {
        String html = "<!DOCTYPE html>\n" +
                "<html><head><meta charset=\"utf-8\"><title>Telemetry Stream Dashboard</title>\n" +
                "<style>body{font-family:system-ui, -apple-system, BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif; padding:20px;} pre{background:#f4f4f4;padding:12px;border-radius:6px;overflow:auto;} button{padding:8px 14px;margin:4px;} </style>\n" +
                "</head><body>\n" +
                "<h1>Telemetry Stream Dashboard</h1>\n" +
                "<p>Click <strong>Refresh</strong> to poll the stream status endpoint.</p>\n" +
                "<button id=\"refresh\">Refresh</button> <button id=\"reset\">Reset Cursor (0-0)</button>\n" +
                "<pre id=\"output\">Loading...</pre>\n" +
                "<script>\n" +
                "const out = document.getElementById('output');\n" +
                "const refresh = document.getElementById('refresh');\n" +
                "const reset = document.getElementById('reset');\n" +
                "function render(data){ out.textContent = JSON.stringify(data, null, 2); }\n" +
                "async function fetchStatus(){\n" +
                "  try {\n" +
                "    const res = await fetch('/api/internal/telemetry/stream-status', { headers: { 'X-Internal-Api-Key': 'dev-internal-key' } });\n" +
                "    const json = await res.json();\n" +
                "    render(json);\n" +
                "  } catch (e) {\n" +
                "    render({error: e.toString()});\n" +
                "  }\n" +
                "}\n" +
                "async function resetCursor(){\n" +
                "  try {\n" +
                "    const res = await fetch('/api/internal/telemetry/stream-status/reset', { method: 'POST', headers: { 'X-Internal-Api-Key': 'dev-internal-key' } });\n" +
                "    const json = await res.json();\n" +
                "    render(json);\n" +
                "  } catch (e) {\n" +
                "    render({error: e.toString()});\n" +
                "  }\n" +
                "}\n" +
                "refresh.addEventListener('click', fetchStatus);\n" +
                "reset.addEventListener('click', resetCursor);\n" +
                "fetchStatus();\n" +
                "</script>\n" +
                "</body></html>";
        return ResponseEntity.ok(html);
    }
}
