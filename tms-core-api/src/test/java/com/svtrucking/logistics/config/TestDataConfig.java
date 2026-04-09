package com.svtrucking.logistics.config;

import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.RoleRepository;
import com.svtrucking.logistics.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Set;

@TestConfiguration
public class TestDataConfig {

    @Bean
    CommandLineRunner initTestDatabase(UserRepository userRepository, RoleRepository roleRepository, PasswordEncoder passwordEncoder) {
        return args -> {
            if (roleRepository.findByName(RoleType.ADMIN).isEmpty()) {
                Role adminRole = new Role();
                adminRole.setName(RoleType.ADMIN);
                roleRepository.save(adminRole);
            }
            if (roleRepository.findByName(RoleType.DRIVER).isEmpty()) {
                Role driverRole = new Role();
                driverRole.setName(RoleType.DRIVER);
                roleRepository.save(driverRole);
            }
            if (roleRepository.findByName(RoleType.SUPERADMIN).isEmpty()) {
                Role superAdminRole = new Role();
                superAdminRole.setName(RoleType.SUPERADMIN);
                roleRepository.save(superAdminRole);
            }


            if (userRepository.findByUsername("superadmin").isEmpty()) {
                User superAdmin = new User();
                superAdmin.setUsername("superadmin");
                superAdmin.setPassword(passwordEncoder.encode("super123"));
                Set<Role> roles = Set.of(
                        roleRepository.findByName(RoleType.SUPERADMIN).get(),
                        roleRepository.findByName(RoleType.ADMIN).get()
                );
                superAdmin.setRoles(roles);
                userRepository.save(superAdmin);
            }
        };
    }
}
