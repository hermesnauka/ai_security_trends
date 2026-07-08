package com.securevision.controller;

import com.securevision.dto.LoginRequest;
import com.securevision.dto.LoginResponse;
import com.securevision.security.JwtService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Dev-only single-admin login: no user table exists yet (Phase 1 scope has no
 * AdminController either). Credentials come from config so they're never
 * hardcoded in source - see application.yml securevision.admin.*. Replace with
 * a real user store before any CRUD endpoint under /api/v1/admin/** ships.
 */
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Auth")
public class AuthController {

    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;
    private final String adminUsername;
    private final String adminPasswordHash;

    public AuthController(
            JwtService jwtService,
            PasswordEncoder passwordEncoder,
            @Value("${securevision.admin.username}") String adminUsername,
            @Value("${securevision.admin.password-hash}") String adminPasswordHash) {
        this.jwtService = jwtService;
        this.passwordEncoder = passwordEncoder;
        this.adminUsername = adminUsername;
        this.adminPasswordHash = adminPasswordHash;
    }

    @PostMapping("/login")
    @Operation(summary = "Exchange admin credentials for a JWT (dev-only single-admin auth)")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        if (!adminUsername.equals(request.username())
                || !passwordEncoder.matches(request.password(), adminPasswordHash)) {
            throw new BadCredentialsException("Invalid username or password");
        }
        String token = jwtService.generateToken(adminUsername, "ADMIN");
        return ResponseEntity.status(HttpStatus.OK).body(LoginResponse.bearer(token, "ADMIN"));
    }
}
