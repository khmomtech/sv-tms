package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

class BannerDtoTest {

    @Test
    void shouldDeserializeSvgImageWithoutFailure() throws Exception {
        String json = "{\"title\":\"Welcome Driver!\",\"imageUrl\":\"https://example.com/image.svg\",\"svgImage\":\"true\",\"startDate\":\"2026-01-01T00:00:00\",\"endDate\":\"2027-01-01T00:00:00\",\"active\":true}";

        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        mapper.configure(com.fasterxml.jackson.databind.DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

        BannerDto dto = mapper.readValue(json, BannerDto.class);

        Assertions.assertNotNull(dto);
        Assertions.assertEquals("Welcome Driver!", dto.getTitle());
        Assertions.assertEquals("https://example.com/image.svg", dto.getImageUrl());
        Assertions.assertTrue(dto.isSvgImage());
    }
}
