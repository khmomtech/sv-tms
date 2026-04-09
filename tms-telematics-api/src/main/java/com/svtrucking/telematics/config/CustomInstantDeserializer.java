package com.svtrucking.telematics.config;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.deser.std.StdDeserializer;
import java.io.IOException;
import java.time.Instant;
import java.time.format.DateTimeParseException;

public class CustomInstantDeserializer extends StdDeserializer<Instant> {

    public CustomInstantDeserializer() {
        super(Instant.class);
    }

    @Override
    public Instant deserialize(JsonParser p, DeserializationContext ctxt)
            throws IOException, JsonProcessingException {
        String text = p.getText().trim();
        try {
            return Instant.parse(text);
        } catch (DateTimeParseException e) {
            if (text.contains(".")) {
                String[] parts = text.split("\\.");
                if (parts.length == 2) {
                    String fractional = parts[1].replaceAll("Z$", "");
                    if (fractional.length() > 3)
                        fractional = fractional.substring(0, 3);
                    text = parts[0] + "." + fractional + "Z";
                }
            }
            return Instant.parse(text);
        }
    }
}
