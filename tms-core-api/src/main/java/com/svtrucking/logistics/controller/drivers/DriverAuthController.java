// package com.svtrucking.logistics.controller.drivers;

// import com.svtrucking.logistics.dto.LoginRequest;
// import com.svtrucking.logistics.dto.RegisterDriverRequest;
// import com.svtrucking.logistics.enums.RoleType;
// import com.svtrucking.logistics.model.Driver;
// import com.svtrucking.logistics.model.Role;
// import com.svtrucking.logistics.model.User;
// import com.svtrucking.logistics.repository.DriverRepository;
// import com.svtrucking.logistics.repository.RoleRepository;
// import com.svtrucking.logistics.repository.UserRepository;
// import com.svtrucking.logistics.security.JwtUtil;

// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.http.HttpStatus;
// import org.springframework.http.ResponseEntity;
// import org.springframework.security.authentication.AuthenticationManager;
// import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
// import org.springframework.security.core.Authentication;
// import org.springframework.security.core.userdetails.UserDetails;
// import org.springframework.security.crypto.password.PasswordEncoder;
// import org.springframework.web.bind.annotation.*;
// import org.springframework.web.multipart.MultipartFile;

// import java.io.IOException;
// import java.nio.file.Files;
// import java.nio.file.Path;
// import java.nio.file.Paths;
// import java.util.*;
// import java.util.stream.Collectors;

// @RestController
// @RequestMapping("/api/drivers/auth")
// public class DriverAuthController {

//     private final AuthenticationManager authenticationManager;
//     private final JwtUtil jwtUtil;
//     private final UserRepository userRepository;
//     private final RoleRepository roleRepository;
//     private final PasswordEncoder passwordEncoder;

//     @Autowired private DriverRepository driverRepository;

//     public DriverAuthController(
//         AuthenticationManager authenticationManager,
//         JwtUtil jwtUtil,
//         UserRepository userRepository,
//         RoleRepository roleRepository,
//         PasswordEncoder passwordEncoder) {

//         this.authenticationManager = authenticationManager;
//         this.jwtUtil = jwtUtil;
//         this.userRepository = userRepository;
//         this.roleRepository = roleRepository;
//         this.passwordEncoder = passwordEncoder;
//     }

//     /**
//      *  **Register Driver with User Account**
//      * 📌 **POST /api/auth/registerdriver**
//      */
//     @PostMapping("/registerdriver")
//     public ResponseEntity<?> registerDriver(@RequestBody RegisterDriverRequest registerRequest,
// @RequestParam Long driverId) {
//         if (registerRequest.getUsername() == null || registerRequest.getPassword() == null ||
// registerRequest.getEmail() == null) {
//             return ResponseEntity.badRequest().body(Map.of("error", "Username, password, and
// email are required"));
//         }

//         if (userRepository.existsByUsername(registerRequest.getUsername())) {
//             return ResponseEntity.badRequest().body(Map.of("error", "Username already exists!"));
//         }

//         //  Encrypt password
//         String encodedPassword = passwordEncoder.encode(registerRequest.getPassword());

//         User user = new User();
//         user.setUsername(registerRequest.getUsername());
//         user.setPassword(encodedPassword);
//         user.setEmail(registerRequest.getEmail());

//         //  Ensure roles are not null
//         Set<String> requestRoles = registerRequest.getRoles();

//         //  Assign DRIVER as default role if roles are missing
//         if (requestRoles == null || requestRoles.isEmpty()) {
//             requestRoles = Set.of("DRIVER");
//         }

//         //  Convert role names to RoleType enum
//         Set<Role> userRoles = requestRoles.stream()
//                 .map(role ->
// roleRepository.findByName(RoleType.valueOf(role.toUpperCase())).orElse(null))
//                 .filter(Objects::nonNull) // Remove null roles
//                 .collect(Collectors.toSet());

//         if (userRoles.isEmpty()) {
//             return ResponseEntity.badRequest().body(Map.of("error", "No valid roles found in
// database"));
//         }

//         user.setRoles(userRoles);
//         userRepository.save(user);
//         return ResponseEntity.ok(Map.of("message", "Driver registered successfully!", "username",
// user.getUsername()));
//     }

//     /**
//      *  **Driver Login API**
//      * 📌 **POST /api/drivers/auth/login**
//      */
//     @PostMapping("/login")
//     public ResponseEntity<?> driverLogin(@RequestBody LoginRequest loginRequest) {
//         Optional<User> optionalUser = userRepository.findByUsername(loginRequest.getUsername());

//         if (optionalUser.isEmpty()) {
//             return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Driver
// not found"));
//         }

//         User user = optionalUser.get();

//         //  Fetch the corresponding driver details
//         Optional<Driver> driverOptional = driverRepository.findById(user.getId());
//         if (driverOptional.isEmpty()) {
//             return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Driver
// not found"));
//         }

//         Driver driver = driverOptional.get();

//         try {
//             Authentication authentication = authenticationManager.authenticate(
//                     new UsernamePasswordAuthenticationToken(loginRequest.getUsername(),
// loginRequest.getPassword()));

//             UserDetails userDetails = (UserDetails) authentication.getPrincipal();
//             String token = jwtUtil.generateToken(userDetails);

//             //  Return driver details including `profilePicture`
//             return ResponseEntity.ok(Map.of(
//                 "token", token,
//                 "driverId", driver.getId(),
//                 "profilePicture", driver.getProfilePicture(),
//                 "user", Map.of(
//                     "username", user.getUsername(),
//                     "email", user.getEmail()
//                 )
//             ));
//         } catch (Exception e) {
//             return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Invalid
// username or password"));
//         }
//     }

//     /**
//      *  **Upload Profile Picture**
//      * 📌 **POST /api/drivers/auth/{driverId}/upload-profile**
//      */
//     @PostMapping("/{driverId}/upload-profile")
//     public ResponseEntity<?> uploadProfilePicture(
//             @PathVariable Long driverId,
//             @RequestParam("profilePicture") MultipartFile file) {

//         Optional<Driver> driverOptional = driverRepository.findById(driverId);

//         if (driverOptional.isEmpty()) {
//             return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Driver not found");
//         }

//         Driver driver = driverOptional.get();

//         try {
//             String fileName = UUID.randomUUID() + "_" + file.getOriginalFilename();
//             Path filePath = Paths.get("uploads/profile_pictures/" + fileName);
//             Files.createDirectories(filePath.getParent());
//             Files.write(filePath, file.getBytes());

//             driver.setProfilePicture("/uploads/profile_pictures/" + fileName);
//             driverRepository.save(driver);

//             return ResponseEntity.ok(Map.of("profilePicture", driver.getProfilePicture()));
//         } catch (IOException e) {
//             return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
//                     .body("Error uploading profile picture");
//         }
//     }
// }
