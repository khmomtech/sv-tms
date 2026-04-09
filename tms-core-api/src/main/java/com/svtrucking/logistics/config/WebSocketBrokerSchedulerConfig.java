// package com.svtrucking.logistics.config;

// import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
// import org.springframework.context.annotation.Bean;
// import org.springframework.context.annotation.Configuration;
// import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;

// @Configuration
// public class WebSocketBrokerSchedulerConfig {

//     @Bean(name = "messageBrokerTaskScheduler")
//     @ConditionalOnMissingBean(name = "messageBrokerTaskScheduler")
//     public ThreadPoolTaskScheduler messageBrokerTaskScheduler() {
//         ThreadPoolTaskScheduler s = new ThreadPoolTaskScheduler();
//         s.setPoolSize(2);
//         s.setThreadNamePrefix("stomp-heartbeat-");
//         s.setRemoveOnCancelPolicy(true);
//         s.initialize();
//         return s;
//     }
// }
