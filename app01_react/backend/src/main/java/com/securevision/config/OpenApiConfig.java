package com.securevision.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.Components;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI secureVisionOpenApi() {
        final String bearerScheme = "bearerAuth";
        return new OpenAPI()
                .info(new Info()
                        .title("SecureVision 2026 API")
                        .description("Interactive reference mapping security threats, vulnerabilities and mitigations across OWASP, MITRE ATLAS and CompTIA frameworks.")
                        .version("v0.1-phase1")
                        .license(new License().name("Educational use - SecureVision 2026 course project")))
                .addSecurityItem(new SecurityRequirement().addList(bearerScheme))
                .components(new Components().addSecuritySchemes(bearerScheme,
                        new SecurityScheme()
                                .name(bearerScheme)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")));
    }
}
