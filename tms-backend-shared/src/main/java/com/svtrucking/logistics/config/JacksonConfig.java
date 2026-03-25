package com.svtrucking.logistics.config;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import java.util.ArrayList;
import java.util.List;
import org.springframework.boot.autoconfigure.http.HttpMessageConverters;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;

@Configuration
public class JacksonConfig {
  @Bean
  ObjectMapper objectMapper() {
    ObjectMapper objectMapper = new ObjectMapper();
    objectMapper.registerModule(new JavaTimeModule());
    objectMapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    objectMapper.configure(com.fasterxml.jackson.databind.DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

    // Prevent Jackson from trying to serialize Spring Data's Pageable (Unpaged) when embedded in Page
    // (Unpaged#pageSize throws UnsupportedOperationException). The API clients only need the data + page metadata.
    objectMapper.addMixIn(PageImpl.class, PageMixin.class);

    return objectMapper;
  }

  private abstract static class PageMixin {
    @JsonIgnore
    abstract Object getPageable();
  }

  @Bean
  HttpMessageConverters customJacksonConverters(ObjectMapper objectMapper) {
    MappingJackson2HttpMessageConverter converter =
        new MappingJackson2HttpMessageConverter(objectMapper);
    List<MediaType> mediaTypes = new ArrayList<>(converter.getSupportedMediaTypes());
    mediaTypes.add(MediaType.valueOf("application/javascript"));
    mediaTypes.add(MediaType.valueOf("text/javascript"));
    converter.setSupportedMediaTypes(mediaTypes);
    return new HttpMessageConverters(converter);
  }
}
