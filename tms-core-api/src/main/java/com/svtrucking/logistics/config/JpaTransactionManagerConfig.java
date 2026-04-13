package com.svtrucking.logistics.config;

import jakarta.persistence.EntityManagerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.transaction.PlatformTransactionManager;

@Configuration
public class JpaTransactionManagerConfig {

    /**
     * Always register the JPA transaction manager under an explicit name.
     * Removing @ConditionalOnMissingBean prevents MongoDB/Kafka TX managers from
     * silently taking the "transactionManager" slot and leaving JPA operations
     * without a bound transaction (TransactionRequiredException on flush).
     * Marked @Primary so plain @Transactional (without explicit name) uses JPA.
     */
    @Bean(name = { "transactionManager", "jpaTransactionManager" })
    @Primary
    public PlatformTransactionManager jpaTransactionManager(EntityManagerFactory entityManagerFactory) {
        return new JpaTransactionManager(entityManagerFactory);
    }
}
